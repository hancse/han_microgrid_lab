import time
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
if matplotlib.__version__.split('.')[0] != '1':
    matplotlib.pyplot.Axes.set_axis_bgcolor = matplotlib.pyplot.Axes.set_facecolor
import matplotlib.gridspec as gs
import copy as cp

class Signal:
    def __init__(self, data, model, user, decimation, sample_time, content):
        self.timestamp = time.strftime('%Y.%m.%d/%H:%M:%S')
        self.decimation = decimation
        self.user = user
        self.sample_time = sample_time
        self.data = data
        self.content = content
        self.primary_tag = ''
        self.secondary_tag = ''
        self.version = 0.1
        self.info = {}

    def __zero_crossings__(self):
        out = self.__setup_dict__()
        idx = len(self.content)
        for i in range(idx):
            size = np.shape(self.data[self.content[i]])
            for j in range(size[1]):
                for z in range(size[0]-1):
                    if round(self.data[self.content[i]][z,j], 3)> 0:
                        if round(self.data[self.content[i]][z+1,j], 3)<= 0:
                            if np.shape(self.data[self.content[i]])[1] > 1:
                                out[self.content[i]][j].append(z)
                            else:
                                out[self.content[i]].append(z)
                    else:
                        if round(self.data[self.content[i]][z+1,j], 3)> 0:
                            if np.shape(self.data[self.content[i]])[1] > 1:
                                out[self.content[i]][j].append(z)
                            else:
                                out[self.content[i]].append(z)
        return out

    def __setup_dict__(self):
        idx = len(self.content)
        pre_dict = []
        for i in range(idx):
            n_col  = np.shape(self.data[self.content[i]])[1]
            if n_col == 1:
                pre_dict.append((self.content[i], []))
            else:
                pre_dict.append((self.content[i], [[] for i in range(n_col)]))
        return dict(pre_dict)

    def set_tag(self, tag):
        self.tag = tag

    def plot(self, title = '', har = []):
        #add a selector to the function
        #plt.style.use('fivethirtyeight')
        size = np.shape(self.data[self.content[0]])
        g = gs.GridSpec(len(self.data.keys()), 1, hspace = 0.3)
        if not har:
            fig = plt.figure(figsize = (12,len(self.content)*4))
            if title !='':
                fig.suptitle(title, fontsize=14)
            t = [i*self.decimation*self.sample_time for i in range(size[0])]
            for i in range(len(self.data.keys())):
                ax = plt.subplot(g[i, 0])
                ax.set_axis_bgcolor('w')
                ax.plot(t, self.data[self.content[i]], linewidth = 1)
                ax.set_xlabel('time [s]', fontsize = 14)
                ax.set_ylabel(self.content[i], fontsize = 14)
                ax.grid(alpha = 0.5, linestyle = 'solid', linewidth = 2, color = '0.75')
        else:
            fig = plt.figure(figsize = (12,len(self.content)*6), dpi = 600)
            props = []
            f = self.frequency()
            H = self.harmonic_content(f, har)
            for k in range(len(self.data.keys())):
                ax = plt.subplot(g[k, 0])
                if type(H[self.content[k]][0]) is list:
                    n_col = len(H[self.content[k]])
                else:
                    n_col = 1
                n_row = len(H['harmonics'])
                space = 0.05
                width = 0.1
                xloc = [[] for i in range(n_col)]
                height = [[] for i in range(n_col)]
                width_array = [[] for i in range(n_col)]
                if n_col%2 == 0:
                    index = []
                    for i in reversed(range(1,(n_col/2)+1)):
                        index.append(-i)
                    for i in range(1,(n_col/2)+1):
                        index.append(i)
                    for i in range(n_col):
                        for j in range(n_row):
                            if abs(index[i]) == 1:
                                xloc[i].append(H['harmonics'][j]+index[i]*(width+space/2)/2)
                            else:
                                xloc[i].append(H['harmonics'][j]+index[i]*(width/2+space))
                            height[i].append(H[self.content[k]][i][j])
                            width_array[i].append(width)
                else:
                    for i in range(n_col):
                        for j in range(n_row):
                            xloc[i].append(H['harmonics'][j]+(i-float((n_col-1)/2))*(space+0.15))
                            if n_col == 1:
                                height[i].append(H[self.content[k]][j])
                            else:
                                height[i].append(H[self.content[k]][i][j])
                            width_array[i].append(width)
                colors = ['blue', 'green', 'red', 'cyan', 'magenta', 'yellow']
                for i in range(n_col):
                    props.append([colors[i], 1, 'solid'])
                for i in range(n_col):
                    ax.bar(xloc[i], height[i], width_array[i], color = colors[i], align = 'center', edgecolor = colors[i], log = True)
                ax.grid(alpha = 0.5, linestyle = 'solid', linewidth = 1, color = '0.75')
                ax.set_axis_bgcolor('w')
                ax.set_xlabel('Harmonics', fontsize=14)
                ax.set_title(title)
                x_text = []
                for i in range(n_row):
                    x_text.append('H_'+str(int(H['harmonics'][i])))
                plt.xticks(H['harmonics'],x_text)


    def frequency(self):
        #to do:
        #------
        #rework the entire function ==> does not always yield good results.
        #implemented for every column of data ==> alter later
        #if __zero_crossings__ reports empty list ==> remove from output and notice user!
        index = self.__zero_crossings__()
        out = self.__setup_dict__()
        delta_index = []
        idx = len(self.content)
        for i in range(idx):
            n_col = np.shape(self.data[self.content[i]])[1]
            for j in range(n_col):
                if n_col == 1:
                    for z in range(len(index[self.content[i]])-1):
                        delta_index.append(index[self.content[i]][z+1] - index[self.content[i]][z])
                    out[self.content[i]].append(round(1/(np.mean(delta_index)*self.sample_time*self.decimation*2.0), 2))
                else:
                    for z in range(len(index[self.content[i]][j])-1):
                        delta_index.append(index[self.content[i]][j][z+1] - index[self.content[i]][j][z])
                    out[self.content[i]][j].append(round(1/(np.mean(delta_index)*self.sample_time*self.decimation*2.0), 2))
        return out

    def harmonic_content(self, frequency, harmonics = [1]):
        DC = False
        idx = len(self.content)
        pre_dict = []
        for i in range(idx):
            n_col  = np.shape(self.data[self.content[i]])[1]
            if n_col == 1:
                pre_dict.append((self.content[i], []))
            else:
                pre_dict.append((self.content[i], [[] for i in range(n_col)]))
        pre_dict.append(('harmonics', cp.deepcopy(harmonics)))
        out = dict(pre_dict)
        for i in range(idx):
            size = np.shape(self.data[self.content[i]])
            #create reference angle
            #assuming each entry of the dict has the same frequency
            theta = [0]
            freq = np.mean(frequency[self.content[i]])
            if harmonics[0] == 0:
                harmonics.pop(0)
                DC = True
            A = np.zeros((size[0],len(harmonics)*2))
            for j in range(size[0]-1):
                if theta[-1]>np.pi:
                    theta.append(theta[-1]+(2*np.pi*freq*self.decimation*self.sample_time)-(2*np.pi))
                else:
                    theta.append(theta[-1]+(2*np.pi*freq*self.decimation*self.sample_time))
                for h in range(len(harmonics)):
                    A[j,(2*h):(2*h)+2] = [np.cos(harmonics[h]*theta[-1]), -np.sin(harmonics[h]*theta[-1])]
            if DC:
                A = np.hstack((np.ones((size[0],1)), A))
            for k in range(size[1]):
                T = np.linalg.lstsq(A, self.data[self.content[i]][:,k])[0]
                if size[1] == 1:
                    if DC:
                        out[self.content[i]].append(T[0])
                        for z in range(len(harmonics)):
                            out[self.content[i]].append(np.sqrt(T[2*z+1]**2 + T[2*z+2]**2))
                    else:
                        for z in range(len(harmonics)):
                            out[self.content[i]].append(np.sqrt(T[2*z]**2 + T[2*z+1]**2))
                else:
                    if DC:
                        out[self.content[i]][k].append(T[0])
                        for z in range(len(harmonics)):
                            out[self.content[i]][k].append(np.sqrt(T[2*z+1]**2 + T[2*z+2]**2))
                    else:
                        for z in range(len(harmonics)):
                            out[self.content[i]][k].append(np.sqrt(T[2*z]**2 + T[2*z+1]**2))
        return out
