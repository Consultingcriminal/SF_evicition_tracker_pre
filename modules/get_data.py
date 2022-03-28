import pandas as pd

def get_evictions_data(year_filter):
    
    ### Getting Data as csv
    eviction_df = pd.read_csv('/home/vulcan/Documents/Niggas_TP/ETL/SF_eviction/eviction_data/Eviction_Notices.csv')

    ### Dropping Unnecessary and Unknown Columns
    my_columns = list(eviction_df.columns)
    terminating_column = my_columns.index('Shape')
    eviction_df = eviction_df[my_columns[:terminating_column+1]]
    
    ### Extracting Latitude And Longitude
    eviction_df[['Latitude','Longitiude']] = eviction_df['Shape'].str.strip("POINT ()").str.split(expand = True)
    eviction_df = eviction_df.drop(['Location','Shape'],axis=1)

    ### Filtering Data according to date in order to aid in incremental-update

    ## Converting To DateTime
    eviction_df['File Date'] =  pd.to_datetime(eviction_df['File Date'], infer_datetime_format=False)

    ## Filtering Values before the year '2013'
    filt = (eviction_df['File Date'] < year_filter)
    eviction_df = eviction_df[filt]

    ## Transforming according to raw_db
    eviction_df.columns = eviction_df.columns.str.replace(' ','_')
    eviction_df.columns = eviction_df.columns.str.lower()

    print(eviction_df.info())
    return eviction_df

if __name__ == '__main__':

    eviction_df = get_evictions_data('2013-01-01')  