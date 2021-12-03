import time
import numpy as np
#import logging as log
from .core import Render as r
from .core import Target as t
from .signal import Signal as s
from IPython.display import display as display
#from IPython.display import clear_output as clear

#define a logger
#logger = log.getLogger(__name__)
#logger.setLevel(log.DEBUG)
#log_str = time.strftime('%Y%m%d') + '.log'
#fh = log.FileHandler(log_str, mode = 'w')
#fh.setLevel(log.DEBUG)
#sh = log.StreamHandler()
#sh.setLevel(log.WARNING)
#formatter = log.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#fh.setFormatter(formatter)
#sh.setFormatter(formatter) #same format used for the time being
#logger.addHandler(fh)
#logger.addHandler(sh)
    
class Model:
    
    def __init__(self, model, host = '', user= 'piet', target = None, model_port = 17726, verbose = False):       
        """
        Create an instance of the class Model. Model uses functionalty of the class Target.
        """ 
        if target is None:
            target = t(host)
        self.target = target
        self.verbose = verbose
        self.model_port = str(model_port)
        self.model = model
        self.user = user
        self.sample_time = 0.0 #Specify the model sample_time when a model is running
        self.parameters = None #Only add available parameters when a model is running.
        self.signals = None #Only add available parameters when a model is running.
        #logger.info('instance of Model created')
        #to do:
        #------
        #Generalize the input of functions set_param and get_signal
        #More intelligent time.sleep for capturing data

    def __trim_url__(self, input_list):
        """
        Set up an dictionary of the string input list. The keys of this dictionary are trimmed to a 
        more human readable format. The values of this dictionary are the full strings. 
        """
        #Trim list of input strings, create unique key by comparing the inputs to each other.
        work_list = []
        pre_dict = []
        full_url = []
        short_url = []
        layer = 1
        for i in range(len(input_list)):
            work_list.append(input_list[i].split('/')[:-1])
        iterator = list(range(len(work_list)))
        while len(iterator) > 0:
            increment = False
            count_list = [[0] for i in range(len(iterator))]
            rm_list = []
            for i in iterator:
                tmp_list = list(range(len(work_list)))
                tmp_list.remove(i)
                for j in tmp_list:
                    try:
                        if work_list[i][-layer:] == work_list[j][-layer:]:
                            count_list[iterator.index(i)][-1] += 1
                    except IndexError:
                        print('Index_error')
            for i in range(len(count_list)):
                tmp_string = ''
                if count_list[i][-1] == 0:
                    for j in range(1,layer+1):
                        if j == 1:
                            tmp_string = work_list[iterator[i]][-j]
                        else:
                            tmp_string =  work_list[iterator[i]][-j] + '/' + tmp_string
                    short_url.append(tmp_string)
                    full_url.append(input_list[iterator[i]])
                    rm_list.append(iterator[i])
                else:
                    increment = True
            for i in range(len(rm_list)):
                iterator.remove(rm_list[i])
            if increment:
                layer += 1
        #Create dictionary.
        for i in range(len(full_url)):
                pre_dict.append((short_url[i], full_url[i]))
        return dict(pre_dict)
        
    def __handle_variables__(self, object, rdm_input = ''):
        """
        Handles the either parameters or signals coming from a running model.
        Performs type casting and checks if the input matches the available
        list of either signals or parameters.
        """
        def __key_error_parameter__(variable):
            print('The following item ' + str(variable) + ' does not correspond to any item provided by the model.')
            print('Note that the no parameters will be set due to this error.')
        
        var_full = []
        var_short = []
        if type(rdm_input) is str:
            if len(rdm_input) == 0:
                for var in object.value:
                    for key in object.options.keys():
                        if key + '/' in var:
                            var_short.append(key)
                            break
                    var_full.append(var)
            else:
                try:
                    var_full.append(object.options[rdm_input])
                except KeyError:
                    __key_error_parameter__(rdm_input)
                var_short.append(rdm_input)
        elif type(rdm_input) is list:
            for var in rdm_input:
                try: 
                    var_full.append(object.options[var])
                except KeyError:
                    __key_error_parameter__(var)
                var_short.append(var)
        else:
            print('Unsupported input type. \n' + 'The supported types are string of list of strings.')
        return (var_short, var_full)
        
    def __check_running__(self):
        if self.status() == 'running':
            out = True
        else:
            out = False
        return out

    def status(self):
        """
        Provide information concerning the state of the model.
        """
        status = self.target.perform_get('model', 'status', {'port':self.model_port}).strip()
        return status 

    def execution_time(self):
        """
        Provide the model execution time in seconds.
        """
        exe_time = self.target.perform_get('model', 'exectime', {'port':self.model_port}).strip()
        return float(exe_time)

    def start(self):
        """
        Start the current model on the Triphase realtime target.
        """
        if self.model== '':
            print('No model currently selected.')
        else:
            props = {'port':self.model_port, 'user':self.user, 'model':self.model}
            self.target.perform_get('model', 'start', props)
            for i in range(0,2):
                if self.status() == 'running':
                    #print('The model: {0} is running.'.format(self.model))
                    display(r.valid(True))
                    description_p = 'Model parameters: '
                    options_p = self.__trim_url__(self.target.perform_get('model-parameters', 'list', {'port':self.model_port}).strip().split()[1:])
                    param_wid = r.select_multiple(description_p, options_p)
                    self.parameters = param_wid
                    description_s = 'Model signals: '
                    options_s = self.__trim_url__(self.target.perform_get('model-signals', 'list', {'port':self.model_port}).strip().split()[1:])
                    signal_wid = r.select_multiple(description_s, options_s)
                    self.signals = signal_wid
                    self.sample_time = float(self.target.perform_get('model', 'sampletime', {'port':self.model_port}).strip())*1e-6
                    #logger.info('model is running')
                    break
                time.sleep(1)
            #if self.status != 'running':
                #logger.warning('the model is not running')
    
    def stop(self):
        """
        Stop the current model on the Triphase realtime target.
        """
        self.target.perform_get('model', 'stop', {'port':self.model_port})
        for i in range(2):
            if self.status() is '':
                print ('The model: {0} has stopped.'.format(self.model))
                #logger.info('model stopped')
                break
            else: 
                print('The model: {0} is still running.'.format(self.model))
                #logger.warning('model is still running')
            time.sleep(1)

    def get_parameter(self, parameters = ''):
        """
        Request a parameter value from the running model.
        """
        pre_dict = []
        if self.__check_running__():
            param_short, param_full = self.__handle_variables__(self.parameters, parameters)
            #get parameter values, one by one
            for i in range(len(param_full)):
                props = {'port':self.model_port, 'name':param_full[i]}
                elements = self.target.perform_get('model-parameters', 'get', props).strip().split()
                if elements[0] is '1' and elements[1] is '1':
                    out = float(elements[-1])
                    pre_dict.append((param_short[i], out))
                else:
                    out = np.zeros((int(elements[0]), int(elements[1])))
                    index = 2
                    for j in range(int(elements[0])):
                        for k in range(int(elements[1])):
                            out[j,k] = float(elements[index])
                            index += 1  
                    pre_dict.append((param_short[i], out))
        else:
            print('Error: The selected model is not running.')
        return dict(pre_dict)

    def set_parameter(self, parameters = '', values = 0.0):
        """
        Set parameter(s) value on a running model. Checks parameter and value integrity.
        """
        value_list = []
        #set inner_functions
        def __count_error__():
            print('Error: \n The number of parameters does not correspond to the number of values.')
            print('Note that the no parameters will be set due to this error.')
            
        def __type_error__(value):
            print('Error: \n The value input type: ' + str(type(value)) + ' is not supported. \n' + 'The supported types are integers, floats and numpy arrays.')
            print('Note that the no parameters will be set due to this error.')
        
        def __integrity_error__(parameter, value):
            if type(value) is float:
                print('Error: \n The parameter {0}'.format(parameter) + ' expects input type: ' + str(type(value)) + '.')
            else:
                size = np.shape(value)
                print('Error: \n The parameter {0}'.format(parameter) + ' expects input type: ' + str(type(value)) + ' with dimensions [{0}, {1}].'.format(size[0], size[1]))
            print('Note that the no parameters will be set due to this error.')
            
        #main
        if self.__check_running__():
            param_short, param_full = self.__handle_variables__(self.parameters, parameters)
            #check appropriate value types
            if type(values) is list:
                if len(param_full) == len(values):
                    for value in values:
                        if type(value) is int:
                            value_list.append(float(value))
                        elif type(value) is float:
                            value_list.append(value)
                        elif type(value) == np.ndarray:
                            value_list.append(value)
                        else:
                            __type_error__(value)
                            return
                else:
                    __count_error__()
            elif type(values) is int:
                value_list.append(float(values))
            elif type(values) is float:
                value_list.append(values)
            elif type(values) == np.ndarray:
                value_list.append(values)
            else:
                __type_error__(values)
                return
            #Set parameters one by one
            for i in range(len(param_full)):
                valid = False
                if type(value_list[i]) is float:
                    tmp = self.get_parameter(param_short[i])[param_short[i]]
                    if type(tmp) is float:
                        tmp_str = '1 1 ' + str(value_list[i]) + ' '
                        print('The parameter: {0} is set to {1}.'.format(param_short[i], value_list[i]))
                        valid = True
                    else:
                        __integrity_error__(param_short[i], tmp)
                        return
                else:
                    tmp = self.get_parameter(param_short[i])[param_short[i]]
                    if np.shape(value_list[i]) == np.shape(tmp):
                        n_row, n_col = np.shape(value_list[i])
                        tmp_str = str(n_row) + ' ' + str(n_col) + ' '
                        for j in range(n_row):
                            for k in range(n_col):
                                tmp_str= tmp_str + str(value_list[i][j,k]) + ' '
                        print('The parameter: {0} is set to the input array.'.format(param_short[i]))
                        valid = True
                    else:
                        __integrity_error__(param_short[i], tmp)
                        return
                if valid:
                    props = {'port' : self.model_port, 'name' : param_full[i], 'value' : tmp_str}
                    self.target.perform_get('model-parameters' , 'set', props)
        else:
            print('Error: The selected model is not running.')
        
    def get_signal(self, signals = ''):
        """
        Request a signal value from a running model.
        """
        pre_dict = []
        if self.__check_running__():
            sig_short, sig_full = self.__handle_variables__(self.signals, signals)
            #get signal one by one
            for i in range(len(sig_full)):
                props = {'port':self.model_port, 'name':sig_full[i]}
                elements = self.target.perform_get('model-signals', 'get', props).strip().split()
                if elements[0] is '1' and elements[1] is '1':
                    out = float(elements[-1])
                    pre_dict.append((sig_short[i], out))
                else:
                    out = np.zeros((int(elements[0]), int(elements[1])))
                    index = 2
                    for j in range(int(elements[0])):
                        for k in range(int(elements[1])):
                            out[j,k] = float(elements[index])
                            index += 1
                    pre_dict.append((sig_short[i], out))
        else:
            print('Error: The selected model is not running.')
        return dict(pre_dict)

    def __list_scopes__(self):
        """
        Generates a list of scopes currently used by the model. These are external mode light scopes, not to be confused
        with actual Mathworks Simulink scopes.
        """
        text = self.target.perform_get('model-scopes', 'list', {'port':self.model_port})
        names = text.strip().split()
        # first line = number of names
        return names[1:]

    def __create_scope__(self, name, signals, size, decimation):
        """
        Create a scope on the realtime target. Sets scope into idle mode.
        """
        signal_str = str(len(signals)) + " "
        for signal in signals:
            signal_str += signal + " "
        props = {'port':self.model_port, 'name':name, 'signals':signal_str, \
                'size':str(size), 'decimation':str(decimation)}
        text = self.target.perform_get('model-scopes', 'create', props)
        return text.strip()

    def __delete_scope__(self, name):
        """
        Delete a scope on the realtime target.
        """
        props = {'port':self.model_port, 'name':name}
        text = self.target.perform_get('model-scopes', 'delete', props)
        return text.strip()

    def __start_scope__(self, name):
        """
        Start an exisiting scope, hence capturing data.
        """
        props = {'port':self.model_port, 'name':name}
        text = self.target.perform_get('model-scopes', 'start', props)
        return text.strip()
            
    def __stop_scope__(self, name):
        """
        Set a scope back into idle mode.
        """
        props = {'port':self.model_port, 'name':name}
        text = self.target.perform_get('model-scopes', 'stop', props)
        return text.strip()

    def __get_scope_data__(self, name):
        """
        Retrieve the captured data from the realtime target.
        """
        props = {'port':self.model_port, 'name':name}
        elements = self.target.perform_get('model-scopes', 'get', props).strip().split()
        out = np.zeros((int(elements[0]), int(elements[1])))
        if elements[0] is '1' and elements[1] is '1':
            out[0,0] = float(elements[-1])
        else:
            index = 2
            for i in range(int(elements[0])):
                for j in range(int(elements[1])):
                    out[i,j] = float(elements[index])
                    index += 1
        return out
        
    def select_signal(self):
        """
        Select one or multiple signals with a neat widget.
        """
        wid = self.signals
        display(wid)
        
    def select_parameter(self):
        """
        Select one or multiple parameters with a neat widget.
        """
        wid = self.parameters
        display(wid)
        
    
    def capture_data(self, signals = '', samples = 1000, decimation = 1):
        """
        Wrapper function which uses the scope_functions in order to capture data from the realtime target.
        A scope is created, started, stopped and deleted in a function call. The function creates an instance of the
        Class Signal. 
        """
        if self.__check_running__():
            sig_short, sig_full = self.__handle_variables__(self.signals, signals)
#        if self.status() == 'running':    
#            signals_full = []
#            signals_short = []
            size_list = []
            pre_dict = []
#            if signals == '':
#                for i in range(len(self.signals.value)):
#                    signals_full.append(self.signals.value[i])
#            else:
#                if type(signals) is str:
#                    signals_full.append(self.signals.options[signals])
#                elif type(signals) is list:
#                    for i in range(len(signals)):
#                        signals_full.append(self.signals.options[signals[i]])     
        #create short urls and check if signal exists
            
            for i in range(len(sig_full)):
#                for item in self.signals.options.items():
#                    if item[1] == signa_full[i]:
#                        signals_short.append(item[0])
                try:
                    size_list.append(np.shape(self.get_signal(sig_short[i])[str(sig_short[i])])[0])
                except IndexError:
                    size_list.append(1)
            scope_name = 'scope'
            Ts = self.sample_time
            self.__create_scope__(scope_name, sig_full, samples, decimation)
            self.__start_scope__(scope_name)
            time.sleep(samples*Ts*decimation*1.05)
            data_scope=self.__get_scope_data__(scope_name)
            self.__stop_scope__(scope_name)
            self.__delete_scope__(scope_name)
            for i in range(len(sig_short)):
                if i == 0:
                    pre_dict.append((sig_short[i], data_scope[:, 0:size_list[i]]))
                else:
                    pre_dict.append((sig_short[i], data_scope[:, sum(size_list[0:i]):sum(size_list[0:i+1])]))
            data = dict(pre_dict)
            
        else:
            print("The model is currently running on the target.")
            data = {}
        out = s(data, self.model, self.user, decimation, self.sample_time, sig_short)
        return out