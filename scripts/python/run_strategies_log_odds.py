"""
This script is to replicate Figure 3, log odds analysis.

The plot used is stored under results/strategies.pdf
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sys
import os

sys.path.append(os.getcwd())
import constants
import math
from collections import defaultdict


def plot_log_odds(df, **kwargs):
    # Assuming top_bottom_df1 and top_bottom_df2 are your two dataframes
    # containing the log odds and topic names for the two different comparisons.

    # Set the style and context for the plots
    sns.set_style('whitegrid')
    sns.set_context("paper", font_scale=0.6, rc={"lines.linewidth": 2.5})

    plt.figure(dpi=600, figsize=(5, 2))

    # Plot positive log odds with blue #4682B4 and negative with red #FF6347, and gray for non-significant (abs(log odds) < 1)
    positive_color = '#4682B4'
    negative_color = '#FF6347'
    non_significant_color = '#D3D3D3'
    sns.barplot(x='log_odds', y='name', data=df, 
                palette=[positive_color if (x < 0 and abs(x) > 1) else negative_color if (x > 0 and abs(x) > 1) else non_significant_color for x in df['log_odds']],
                edgecolor='black', linewidth=0.5)
    plt.xlabel(kwargs.get('title', 'Log odds ratio'))
    plt.ylabel('')
    
    x_min, x_max = plt.xlim(-5, 5)
    y_min, y_max = plt.ylim()
    plt.text(x_min, y_max-0.5, kwargs.get('text_left', ''), ha='left', va='center') # second group because it's negative
    plt.text(x_max, y_max-0.5, kwargs.get('text_right', ''), ha='right', va='center')

    # Adjust layout
    plt.tight_layout()
    plt.savefig(kwargs.get('output_fname', "../../output/log_odds.pdf"))
    # plt.show()

def _log_odds(counts1, counts2, prior, zscore = True):
    # code from Dan Jurafsky
    # note: counts1 will be positive and counts2 will be negative
    sigmasquared = defaultdict(float)
    sigma = defaultdict(float)
    delta = defaultdict(float)

    n1 = sum(counts1.values())
    n2 = sum(counts2.values())

    # since we use the sum of counts from the two groups as a prior, this is equivalent to a simple log odds ratio
    nprior = sum(prior.values())
    for word in prior.keys():
        if prior[word] == 0:
            delta[word] = 0
            continue
        l1 = float(counts1[word] + prior[word]) / (( n1 + nprior ) - (counts1[word] + prior[word]))
        l2 = float(counts2[word] + prior[word]) / (( n2 + nprior ) - (counts2[word] + prior[word]))
        sigmasquared[word] = 1/(float(counts1[word]) + float(prior[word])) + 1/(float(counts2[word]) + float(prior[word]))
        sigma[word] = math.sqrt(sigmasquared[word])
        delta[word] = (math.log(l1) - math.log(l2))
        if zscore:
            delta[word] /= sigma[word]
    return delta

def run_log_odds(corpusA, corpusB, value_column):
    counts1 = corpusA[value_column].value_counts().to_dict()
    counts2 = corpusB[value_column].value_counts().to_dict()
    prior = {}
    for k, v in counts1.items():
        prior[k] = v + counts2[k]

    log_odds = _log_odds(counts1, counts2, prior, True)
    log_odds_df = pd.DataFrame.from_dict(log_odds, orient='index', columns=['log_odds'])
    log_odds_df = log_odds_df.sort_values(by='log_odds', ascending=False)
    top_bottom_df = pd.concat([log_odds_df[log_odds_df['log_odds'] >= 0], 
                                log_odds_df[log_odds_df['log_odds'] <= 0]])
    top_bottom_df = top_bottom_df.reset_index().rename(columns={'index': 'name'})
    return top_bottom_df


def run_analysis():
    # Utt corpus should be annotated with appropriate columns
    corpus = pd.read_csv(
        "../../datafiles/messages/annotated_strategies.csv"
    )

    # Report log likelihood of strategies between TUTOR_COPILOT_ASSIGNMENT = TREATMENT and CONTROL.
    strategy_names = [f"strategies-{index}" for index in constants.STRATEGY_ID_2_NAME.keys()]

    # Remove "strategies-1"
    strategy_names.remove("strategies-1")

    # Check that columns exist
    for name in strategy_names:
        if name not in corpus.columns:
            raise ValueError(f"Column {name} not in corpus")
    # log odds per strategy
    control_df = corpus[corpus["TUTOR_COPILOT_ASSIGNMENT"] == "CONTROL"]
    treatment_df = corpus[corpus["TUTOR_COPILOT_ASSIGNMENT"] == "TREATMENT"]

    strategy_2_log_odds = []
    for strategy_name in strategy_names:
        # Note: log odds treatment - control. So if log odds is positive, treatment > control. Vice versa.
        log_odds_df = run_log_odds(
            treatment_df, control_df, strategy_name)

        # Get the log odds value for 1.0
        log_odds = log_odds_df[log_odds_df['name'] == 1.0]['log_odds'].values[0]
        strategy_2_log_odds.append({"name": strategy_name, "log_odds": log_odds})

    strategy_log_odds_df = pd.DataFrame(strategy_2_log_odds)

    # Rename the strategies
    strategy_nl = constants.CLASSIFIER_STRATEGY_NL
    strategy_log_odds_df['name'] = strategy_log_odds_df['name'].apply(lambda x: strategy_nl[x])

    strategy_log_odds_df = strategy_log_odds_df.sort_values(by='log_odds', ascending=False)
    plot_log_odds(
        strategy_log_odds_df, 
        title="Z-scored log odds ratio", 
        text_left="Control", # Negative values mean that control > treatment
        text_right="Treatment", # Positive values mean that treatment > control
        output_fname="../../output/log_odds.pdf"
        )

if __name__ == "__main__":
    run_analysis()