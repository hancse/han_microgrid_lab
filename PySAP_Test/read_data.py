# -*- coding: utf-8 -*-
"""
Created on Thu Apr 15 12:47:55 2021

@author: TrungNguyen
"""
import pandas as pd
import numpy as np
from pathlib import Path
#from joblib import dump
#seq_length = 12

def read_file(filename,index):
    
    """ Prepare data for the model with the following steps:
    
    - Read data from the data file.
    - Do normalize the data, and save the scaler for the prediction. 
    - Split the data into traning set (80%) and test set (20%).
    - Create a time lag for training set and prediction set.
    
        https://datascience.stackexchange.com/questions/72480/what-is-lag-in-time-series-forecasting#:~:text=Lag%20features%20are%20target%20values,models%20some%20kind%20of%20momentum.
    -
   
    Args:
        
        filename:     name of the data set.
        seq_length:   the number of pass input points which needed 
                      for predicting the future value.                     
      
    Returns:
       
        dataX:       input data (train + test).    
        dataY:       prediction data.   
        trainX:      train input data.
        trainY:      train prediction data.
        testX:       test input data. 
        TestY:       test prediction data.
        
    """
    
    data_dir = Path.cwd() #/ 'data'    
    file = filename
  
    df = pd.read_csv(data_dir/file)
    
    if (len(df) >= 48):
        resize= 48
	
    else:
        
        resize = len(df) -1
	
    #print(resize)
    #print(df['PV'][0:resize])

    bev_usage = pd.Series(df['EV'].values[0:resize], index[0:(len(df)-0)])
    P_pv_pu_Test = pd.Series(df['PV'].values[0:resize], index[0:(len(df)-0)])

   
    return P_pv_pu_Test,bev_usage

if __name__ == "__main__":
    
    filename = 'demo.csv'
    # use 24 hour period for consideration
    
    index = pd.date_range("2021-01-01 00:00","2021-01-02 23:00", freq="H")
    
    #P_pv_pu_Test, bev_usage = read_file(filename,index)
    
    #print(index[0:10])
    #print(bev_usage)
    #print(P_pv_pu_Test)


