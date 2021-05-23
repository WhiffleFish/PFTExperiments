import pandas as pd

def collapse(df):
    times = df['times']
    df = df.drop('times', axis=1)
    new_df = pd.DataFrame(columns=['times','policy', 'result'])
    for col in df.columns:
        tmp = pd.concat([times,df[col]], axis=1)
        tmp = tmp.rename(columns={col:'result'})
        tmp['policy'] = [col]*len(tmp)
        new_df = pd.concat([new_df,tmp], axis=0)
    return new_df

