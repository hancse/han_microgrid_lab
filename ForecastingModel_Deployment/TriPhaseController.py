import sqlite3
import paramiko
import ftplib
import sys                               #for path                    
import time                              #for time.sleep
import pandas as pd
import tripy as trp                      #for triphase
import numpy as np                       #for np.array

from IPython.display import clear_output
from scipy.interpolate import interp1d   #for piecewise linear
from IPython.display import display
from pathlib import Path

''' If the time diff is larger than 600s (10 minutes), then data are assumed loss and E is 0 '''

def removeLargeDiff(diff_in):
    if (diff_in > 1000):
        return 0
    return diff_in

def calculateEnergy(data_in):
    data_out = data_in.copy()
    data_out['Power'] = data_out['P1'] + data_out['P2'] + data_out['P3']
    data_out.loc[:,'Time_diff'] = data_out.Time_diff.shift(-1)
    data_out = data_out.iloc[:-1,:]
    data_out['Time_diff'] = data_out.Time_diff.map(removeLargeDiff)
    data_out['Energy_kWh'] = data_out['Power'] * data_out['Time_diff'] / 3600000
    data_out = data_out[['Energy_kWh']].groupby(pd.Grouper(freq='1H')).sum()
    return data_out

class Database:
    """ A ssh connection to the databse"""
    def __init__ (self, host_ip = "192.168.110.7", port = 22, password = "controlsystem", username = "pi", wdir = '/mnt/dav/Data', MBdatabase = "modbusData.db", EVdatabase = "usertable.sqlite3"):       
        """Set up the ssh connection.
        
        Keyword arguments:
        host_ip -- The IP address of the database (default 192.168.100.7)
        port -- The ssh port (default 22)
        password -- The ssh password (default controlsystem)
        username -- The ssh username (default pi)
        wdir -- The absoulute path to the folder that containing the databases (default /mnt/dav/Data)
        MBdatabase -- The Modbus database (default modbusData.db)
        EVdatabase -- The EV (wifi) database (default usertable.sqlite3)
        """
        
        self.host_ip = host_ip
        self.port = port
        self.password = password
        self.username = username
        self.wdir = wdir
        self.MBdatabase = MBdatabase
        self.EVdatabase = EVdatabase

        
    def read_PV (self, hours=1, host_ip=None, port=None, password=None, username=None, wdir=None, MBdatabase=None):
        """
        Read the latest PV data from the databse.
        
        Keyword arguments:
        hours -- number of hours of data that need to be read (default 1).
        
        Return:
        The average value of PV in the last hours.
        """
        
        if host_ip==None:
            host_ip = self.host_ip
        if port==None:
            port=self.port
        if password==None:
            password=self.password
        if username==None:
            username=self.username
        if wdir==None:
            wdir=self.wdir
        if MBdatabase==None:
            MBdatabase=self.MBdatabase
        
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host_ip, port, username, password)

        ftp = ssh.open_sftp()
    
        data_d = ftp.chdir(wdir)
        #cwd = ftp.getcwd()
        #path = Path.cwd()
        
        ftp.get(MBdatabase,MBdatabase,callback=None)
        
        conn_PV = sqlite3.connect(MBdatabase)
        
        rows = hours*50
        
        query = '''SELECT Time,P1,P2,P3 FROM PV ORDER BY No DESC LIMIT ''' + str(rows)
        PV_data = pd.read_sql_query(query, conn_PV)
        PV_data['Time'] = pd.to_datetime(PV_data['Time'],unit='s')
    
        # PV data hourly rate resample
        PV_data = PV_data.sort_values(by='Time', ascending=True)
        PV_data['Time'] = pd.to_datetime(PV_data['Time'],unit='s')
        PV_data = PV_data.set_index('Time')

        PV_data = PV_data.resample('60min').mean()
        PV_data = PV_data.tail(hours)
        #PV_data = PV_data.tail(1)
        
        self.conn_PV.close()
        
        P1_list = np.array(PV_data['P1'].to_list())
        P2_list = np.array(PV_data['P2'].to_list())
        P3_list = np.array(PV_data['P3'].to_list())
        
        return np.add(P1_list,P2_list,P3_list)
    
        
    def read_PV_df (self, hours=1, host_ip=None, port=None, password=None, username=None, wdir=None, MBdatabase=None):
        """
        Read the latest PV data from the databse.
        
        Keyword arguments:
        hours -- number of hours of data that need to be read (default 1).
        
        Return:
        Pandas dataframe with hourly accumulated PV Energy.
        """
        
        if host_ip==None:
            host_ip = self.host_ip
        if port==None:
            port=self.port
        if password==None:
            password=self.password
        if username==None:
            username=self.username
        if wdir==None:
            wdir=self.wdir
        if MBdatabase==None:
            MBdatabase=self.MBdatabase
        
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host_ip, port, username, password)

        ftp = ssh.open_sftp()
    
        data_d = ftp.chdir(wdir)
        #cwd = ftp.getcwd()
        #path = Path.cwd()
        
        ftp.get(MBdatabase,MBdatabase,callback=None)
        
        conn_PV = sqlite3.connect(MBdatabase)
        
        rows = hours*50
        
        query = '''SELECT Time,P1,P2,P3 FROM PV ORDER BY No DESC LIMIT ''' + str(rows)
        PV_data = pd.read_sql_query(query, conn_PV)
        PV_data['Time'] = pd.to_datetime(PV_data['Time'],unit='s')
    
        # PV data hourly rate resample
        PV_data = PV_data.sort_values(by='Time', ascending=True)
        PV_data['Time'] = pd.to_datetime(PV_data['Time'],unit='s')
        PV_data = PV_data.set_index('Time')
        
        PV_data.loc[:,'Time_diff'] = (PV_data.index.to_series().diff()).dt.total_seconds()
        return calculateEnergy(PV_data).iloc[-hours:,:]
    
    
    def read_Grid_df (self, hours=1, host_ip=None, port=None, password=None, username=None, wdir=None, MBdatabase=None):
        """
        Read the latest Grid data from the databse.
        
        Keyword arguments:
        hours -- number of hours of data that need to be read (default 1).
        
        Return:
        Pandas dataframe with hourly accumulated Grid Energy.
        """
        
        if host_ip==None:
            host_ip = self.host_ip
        if port==None:
            port=self.port
        if password==None:
            password=self.password
        if username==None:
            username=self.username
        if wdir==None:
            wdir=self.wdir
        if MBdatabase==None:
            MBdatabase=self.MBdatabase
        
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host_ip, port, username, password)

        ftp = ssh.open_sftp()
    
        data_d = ftp.chdir(wdir)
        #cwd = ftp.getcwd()
        #path = Path.cwd()
        
        ftp.get(MBdatabase,MBdatabase,callback=None)
        
        conn_Grid = sqlite3.connect(MBdatabase)
        
        rows = hours*50
        
        query = '''SELECT Time,P1,P2,P3 FROM Grid ORDER BY No DESC LIMIT ''' + str(rows)
        Grid_data = pd.read_sql_query(query, conn_Grid)
        Grid_data['Time'] = pd.to_datetime(Grid_data['Time'],unit='s')
    
        # Grid data hourly rate resample
        Grid_data = Grid_data.sort_values(by='Time', ascending=True)
        Grid_data['Time'] = pd.to_datetime(Grid_data['Time'],unit='s')
        Grid_data = Grid_data.set_index('Time')
        
        Grid_data.loc[:,'Time_diff'] = (Grid_data.index.to_series().diff()).dt.total_seconds()
        return calculateEnergy(Grid_data).iloc[-hours:,:]
          
    
    def read_EV (self, hours=1, host_ip=None, port=None, password=None, username=None, wdir=None, EVdatabase=None):
        """
        Read the latest EV data from the databse.
        
        Keyword arguments:
        hours -- number of hours of data that need to be read (default 1)
        
        Return:
        The average of total power of all charging stations in the last hours.
        """
        
        if host_ip==None:
            host_ip = self.host_ip
        if port==None:
            port=self.port
        if password==None:
            password=self.password
        if username==None:
            username=self.username
        if wdir==None:
            wdir=self.wdir
        if EVdatabase==None:
            EVdatabase=self.EVdatabase
        
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host_ip, port, username, password)

        ftp = ssh.open_sftp()
    
        data_d = ftp.chdir(wdir)
        #cwd = ftp.getcwd()
        #path = Path.cwd()
        
        ftp.get(EVdatabase,EVdatabase,callback=None)
        
        conn_EV = sqlite3.connect(EVdatabase)
        
        rows = hours*200
        
        ####################################################################################
        ##################################SocketID = 1######################################
        query = '''SELECT * FROM measurements WHERE socketId=1 ORDER BY Time DESC LIMIT ''' + str(rows)
        EV1_data = pd.read_sql_query(query, conn_EV)
        EV1_data['Time'] = pd.to_datetime(EV1_data['Time'],unit='s')
    
        # EV data hourly rate resample
        EV1_data = EV1_data.sort_values(by='Time', ascending=True)
        EV1_data['Time'] = pd.to_datetime(EV1_data['Time'],unit='s')
        EV1_data = EV1_data.set_index('Time')
        EV1_data = EV1_data.resample('60min').mean()
        EV1_data = EV1_data.tail(hours)
        
        
        ####################################################################################
        ##################################SocketID = 2######################################
        query = '''SELECT * FROM measurements WHERE socketId=2 ORDER BY Time DESC LIMIT ''' + str(rows)
        EV2_data = pd.read_sql_query(query, conn_EV)
        EV2_data['Time'] = pd.to_datetime(EV2_data['Time'],unit='s')
    
        # EV data hourly rate resample
        EV2_data = EV2_data.sort_values(by='Time', ascending=True)
        EV2_data['Time'] = pd.to_datetime(EV2_data['Time'],unit='s')
        EV2_data = EV2_data.set_index('Time')
        EV2_data = EV2_data.resample('60min').mean()
        EV2_data = EV2_data.tail(hours)
        
        
        ####################################################################################
        ##################################SocketID = 3######################################
        query = '''SELECT * FROM measurements WHERE socketId=3 ORDER BY Time DESC LIMIT ''' + str(rows)
        EV3_data = pd.read_sql_query(query, conn_EV)
        EV3_data['Time'] = pd.to_datetime(EV3_data['Time'],unit='s')
    
        # EV data hourly rate resample
        EV3_data = EV3_data.sort_values(by='Time', ascending=True)
        EV3_data['Time'] = pd.to_datetime(EV3_data['Time'],unit='s')
        EV3_data = EV3_data.set_index('Time')
        EV3_data = EV3_data.resample('60min').mean()
        EV3_data = EV3_data.tail(hours)
        
        
        ####################################################################################
        ##################################SocketID = 4######################################        
        query = '''SELECT * FROM measurements WHERE socketId=1 ORDER BY Time DESC LIMIT ''' + str(rows)
        EV4_data = pd.read_sql_query(query, conn_EV)
        EV4_data['Time'] = pd.to_datetime(EV4_data['Time'],unit='s')
    
        # EV data hourly rate resample
        EV4_data = EV4_data.sort_values(by='Time', ascending=True)
        EV4_data['Time'] = pd.to_datetime(EV4_data['Time'],unit='s')
        EV4_data = EV4_data.set_index('Time')
        EV4_data = EV4_data.resample('60min').mean()
        EV4_data = EV4_data.tail(hours)
        
        
        EV1_I1_ls = np.array(EV1_data['I1'].to_list())
        EV1_I2_ls = np.array(EV1_data['I2'].to_list())
        EV1_I3_ls = np.array(EV1_data['I3'].to_list())
        EV1_V1_ls = np.array(EV1_data['V1'].to_list())
        EV1_V2_ls = np.array(EV1_data['V2'].to_list())
        EV1_V3_ls = np.array(EV1_data['V3'].to_list())
        
        EV2_I1_ls = np.array(EV2_data['I1'].to_list())
        EV2_I2_ls = np.array(EV2_data['I2'].to_list())
        EV2_I3_ls = np.array(EV2_data['I3'].to_list())
        EV2_V1_ls = np.array(EV2_data['V1'].to_list())
        EV2_V2_ls = np.array(EV2_data['V2'].to_list())
        EV2_V3_ls = np.array(EV2_data['V3'].to_list())
        
        EV3_I1_ls = np.array(EV3_data['I1'].to_list())
        EV3_I2_ls = np.array(EV3_data['I2'].to_list())
        EV3_I3_ls = np.array(EV3_data['I3'].to_list())
        EV3_V1_ls = np.array(EV3_data['V1'].to_list())
        EV3_V2_ls = np.array(EV3_data['V2'].to_list())
        EV3_V3_ls = np.array(EV3_data['V3'].to_list())
        
        EV4_I1_ls = np.array(EV4_data['I1'].to_list())
        EV4_I2_ls = np.array(EV4_data['I2'].to_list())
        EV4_I3_ls = np.array(EV4_data['I3'].to_list())
        EV4_V1_ls = np.array(EV4_data['V1'].to_list())
        EV4_V2_ls = np.array(EV4_data['V2'].to_list())
        EV4_V3_ls = np.array(EV4_data['V3'].to_list())
        
        EV_Power = 2*(EV1_I1_ls*EV1_V1_ls + EV1_I2_ls*EV1_V2_ls + EV1_I3_ls*EV1_V3_ls +
                      EV2_I1_ls*EV2_V1_ls + EV2_I2_ls*EV2_V2_ls + EV2_I3_ls*EV2_V3_ls +
                      EV3_I1_ls*EV3_V1_ls + EV3_I2_ls*EV3_V2_ls + EV3_I3_ls*EV3_V3_ls +
                      EV4_I1_ls*EV4_V1_ls + EV4_I2_ls*EV4_V2_ls + EV4_I3_ls*EV4_V3_ls)
        
        conn_EV.close()
        
        return EV_Power 
    
    
class Controller:
    """A class to wrap the database, triphase controller with some additional functions
    
    Attributes:
        SOC_checkpoints  Threshold values of SOC used in calculating the SOC of the battery from the Voltage
        SOC_breakpoints  Values of V_battery associated with SOC_checkpoints
    """
    
    SOC_checkpoints = np.array([0, 9, 14, 17, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100])
    SOC_breakpoints = np.array([300, 360, 374.4, 384, 386.4, 390, 392.4, 393.6, 394.8, 396, 397.2, 398.4, 415.2, 433.2, 438])
        
    def __init__ (self, in_model = 'PM15A30I60F06_afAC3_vsAC3_csDC1', in_user = 'piet', in_host = '172.22.151.35'):
        """Set up database and triphase control model. The controller runs in demo mode by default.
        
        Keyword arguments:
        in_model -- Name of the triphase model (default PM15A30I60F06_afAC3_vsAC3_csDC1)
        in_user -- Username for the triphase model (default piet)
        in_host -- IP address of the triphase model (default 172.22.151.35)
        """
        
        # Battery
        self.SOC = 0
        self.V_battery = 0
        
        # Triphase controller
        #self.model = in_model
        #self.user = in_user
        #self.host = in_host
        
        self.f = interp1d(self.SOC_breakpoints, self.SOC_checkpoints)
        #self.m = trp.Model(model = in_model, user = in_user, host = in_host)
        self.control_callback = None
        self.demo_callback = None
        
        self.PV_list = []
        self.EV_list = []
        
    #def __del__(self):
    #    self.m.stop()
    
    def set_PV(self, data=[]):
        self.PV_list = data
        
    def set_EV(self, data=[]):
        self.EV_list = data        
        
    def start_model(self):
        """Start the triphase control model.
        """
        
        # Start the model
        self.m.start()

        self.m.set_parameter('COMMAND_CENTER/External_param', 1)
        self.m.set_parameter('syst/precharge_P30_1', 1)
        time.sleep(10)
        #u_dcbus = self.m.capture_data('af/u_dcbus', samples = 2000, decimation = 1)
        #u_dcbus.plot()
        self.m.set_parameter('af/enable', 1)
        time.sleep(2)
        self.m.set_parameter('syst/precharge_P30_1', 0)
        
        #self.m.set_parameter('cs/i_ph', 0)
        
        
    def stop_model(self):
        """Stop the triphase control model.
        """
        
        # change the current SP back to 0
        self.m.set_parameter('cs/i_ph', 0)
        # Disconnect the cs
        self.m.set_parameter('cs/enable', 0)
        # Disconnect the transfomer
        self.m.set_parameter('transfo/connect', 0)
        
        # Disable the Af
        self.m.set_parameter('af/enable', 0)
        time.sleep(20)
        # Disable external command
        self.m.set_parameter('COMMAND_CENTER/External_param', 0)
        
        #Stop the model
        self.m.stop()
    
    
    def set_battery_control(self,c_sp):
        """turn on the battery control.
           c_sp: current setpoint for charging and discharing the battery.
           
        """
        
        # connect dc bus with battery
        self.m.set_parameter('transfo/connect', 1)
        time.sleep(5)
        self.m.set_parameter('cs/enable', 1)
        m.set_parameter('cs/i_ph', c_sp)
        
        #self.m.set_parameter('cs/i_ph', 0)    
        
        
    def find_SOC(self):
        """Measure the output voltage of the battery and calculate the SOC.
        """
        cs_out = self.m.capture_data('cs/u_out', samples = 1, decimation = 2)
        [out_data] = list(cs_out.data.values())
            
        self.V_battery = int(out_data.item() * 5) / 5
        self.SOC = round(self.f(self.V_battery).item(),1)
        
        return self.SOC
        
    def find_SOC_past(self):
        out = []
        cs_out = self.m.capture_data('cs/u_out', samples = 50, decimation = 2)
        [out_data] = cs_out.data.values()
        
        for i in range(len(out_data)):
            V_battery = int(out_data[i] * 5) / 5
            SOC = round(self.f(V_battery).item(),1)
            out.append(SOC)
            
        return out
    
    
    def set_callback(self, fnc):
        """Assign the callback function to control the model.
        The callback function must have the format: control_callback(SOC, EV_arr, PV_arr)
        in which EV_arr and PV_arr are the predictions of P_ev and P_pv, SOC is the current State of Charge,
        and the callback must return the prediction of current value I.
        """
        self.control_callback = fnc
           
    
    def power_control(self):
        """Run the control algorithm.
        
        Keyword arguments:
        dat_arr -- List of input data in format [SOC, EV_arr, PV_arr]. 
                This arguments is not necessary in normal working mode.
        
        Return:
        In demo mode: A list of SOC in the future, at the same time as in the input data.
        In normal working mode: The current I (output of the callback function).
        """
       
        self.find_SOC()          
        I_val = self.control_callback(self.SOC, self.EV_list, self.PV_list)
        
        #print('I = ', I_val)
        self.set_battery_control(I_val)
            
            
        