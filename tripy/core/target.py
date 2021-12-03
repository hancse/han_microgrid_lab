import sys, urllib.request
import socket as sckt
from .render import Render as r
from IPython.display import display as display
from IPython.display import clear_output as clear

class Target:
    def __init__(self, host, apache_port = 80, verbose = False):
        target_lib = self.find_targets(default_ip = host)
        if self.__check_target__(target_lib, host):
            self.host = host
        else:
            description = 'Select one of the available Triphase realtime targets: '
            pre_dict = []
            for i in range(len(target_lib['ips'])):
                pre_dict.append((target_lib['names'][i], target_lib['ips'][i]))
            options = dict(pre_dict)
            out = r.select(description, options)
            display(out)
            self.host = target_lib['ips'][0]
            out.on_trait_change(self.__change_host__, 'value')
            self.host = out.value
        self.apache_port = apache_port
        self.verbose = verbose
        self.version = sys.version_info[0]

    def __change_host__(self, name, value):
        self.host = value
        clear()
        print('Selected: ' + value)

    def find_targets(self, default_ip = '192.168.0.255', default_port = 8282):
        target_names = []
        target_ips = []
        s = sckt.socket(sckt.AF_INET, sckt.SOCK_DGRAM)
        s.setsockopt(sckt.SOL_SOCKET, sckt.SO_BROADCAST, 1)
        s.settimeout(0.1)
        string = 'GETHOSTNAME\0'
        out_data = string.encode('us-ascii')
        broadcast_ip = default_ip.rsplit('.', 1)[0] + '.255'
        #s.sendto(out_data, (broadcast_ip, default_port))
        s.sendto(out_data, ('172.22.151.35', default_port))
        while True:
            try:
                in_data, addr = s.recvfrom(256)
                target_names.append(in_data.decode())
                target_ips.append(addr[0])
            except sckt.error:
                break
        return {'ips' : target_ips, 'names' : target_names}

    def __check_target__(self, target_lib, ip):
        if type(ip) != 'str':
            ip = str(ip)
        if ip in target_lib['ips']:
            found = True
        else:
            found = False
        return found

    def perform_get(self, resource, command, properties = {}, api='/api/v1'):
        url = 'http://' + self.host
        url += api + '/' + resource + '.php'
        url += '?command=' + command
        for key, value in properties.items():
            url += '&' + key + '=' + value
        url = url.replace(' ', '+')
        if self.verbose:
            print ('log_url: {0}'.format(url))
        text = str(urllib.request.urlopen(url).read(), encoding='UTF-8')
        return text

    def add_message(self, type, title, content, sender):
        props = {'type': type, 'title': title, 'content': content, 'from': sender}
        text = self.perform_get('messages', 'addmessage', props, api="/gui")
        return text
