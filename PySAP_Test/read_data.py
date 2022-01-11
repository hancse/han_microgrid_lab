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

def read_file(filename):
    
    """ Prepare data for the model with the following steps:
    
    - Read data from the data file.
    - Do normalize the data, and save the scaler for the prediction. 
    - Split the data into traning set (80%) and test set (20%).
    - Create a time lag for training set and prediction set.
    
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
    index = pd.date_range("2021-01-01 00:00","2021-01-02 23:00", freq="H")

    #data_dir = Path.cwd() #/ 'data'
    data_dir = '/home/pi/PySAP_Test/'    

    file = filename
  
    df = pd.read_csv(data_dir + file)
    
    if (len(df) >= 48):
        resize= 48
	
    else:
        
        resize = len(df) -0
	
    #print(resize)
    #print(df['PV'][0:resize])

    bev_usage = pd.Series(df['EV'].values[0:resize], index[0:(len(df)-0)])
    P_pv_pu_Test = pd.Series(df['PV'].values[0:resize], index[0:(len(df)-0)])
    
    # day tariff
    day_p_max_pu = pd.Series(0, index[0:(len(df)-0)])
    day_p_max_pu["2021-01-01 07:00":"2021-01-01 22:00"] = 1.
    day_p_max_pu["2021-01-02 07:00":"2021-01-02 22:00"] = 1.
    #print(day_p_max_pu)
    
    # night tariff
    night_p_max_pu = pd.Series(0, index[0:(len(df)-0)])
    night_p_max_pu["2021-01-01 00:00":"2021-01-01 07:00"] = 1.
    night_p_max_pu["2021-01-02 00:00":"2021-01-02 07:00"] = 1.
    #print(night_p_max_pu)
    
    index = index[0:(len(df)-0)]
   
    return P_pv_pu_Test,bev_usage,day_p_max_pu,night_p_max_pu,index

if __name__ == "__main__":
    
    filename = 'demo.csv'
    # use 24 hour period for consideration
    
    index = pd.date_range("2021-01-01 00:00","2021-01-02 23:00", freq="H")
    
    P_pv_pu_Test, bev_usage,day_p_max_pu,night_p_max_pu = read_file(filename,index)
    
    print(len(P_pv_pu_Test))
    print(len(bev_usage))
    print(len(day_p_max_pu))
    print(len(night_p_max_pu))

    #print(index[0:(len(P_pv_pu_Test)-0)])
    #print(bev_usage)
    #print(P_pv_pu_Test)


