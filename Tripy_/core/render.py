#Use the following to use with IPython 3.2
#import IPython.html.widgets as wid 
import ipywidgets as wid

class Render:
    """
    Class that wraps all necessary widgets 
    """    
    def select(description, options):
        widget = wid.Select(description = description + ':', options = options)
        return widget
    
    def dropdown(description, options):
        widget = wid.Dropdown(description = description + ':', options = options)
        return widget
    
    def select_multiple(description, options):
        widget = wid.SelectMultiple(description = description + ':', options = options)
        return widget
        
    def button(text):
        widget = wid.Button(description = text)
        return widget
        
    def valid(boolean):
        widget = wid.Valid(value = boolean)
        return widget
        
    def html(string = ''):
        widget = wid.HTML(string)
        return widget
        
class Output:   
    """
    Class that uses the html widget from the Render class to output a specific
    message (either feedback or an error) in a neater format.
    """
    def __init__(self):
        self.text_color = '#333333'
        self.tag_text_color = '#ffffff'
        self.border_color = '#eeeeee'
        self.background_color = '#f5f5f5'
        self.font = 'Verdana,sans-serif'
        self.box_r = '5px'
        self.tag_r = '3px'
        tmp_str = """<div style ='border-width: thin; color: {0}; border-style: solid; border-color: {1};
                            border-radius: {2} ; text-align: left; padding: 5px; padding-left: 5px;
                            padding-right: 5px; font-family: {3}; background-color: {4}'>""".format(self.text_color, self.border_color, self.box_r, self.font, self.background_color)
        tmp_str += "<table style = 'width: 100%'><tr><th></th></tr></table>"
        tmp_str += "<table style = 'width: 100%'><tr></tr></table></div>"
        self.html = tmp_str
        
        
    def __set_tag_color__(self, tag_type = ''):
        #colors from www.color-hex.com/color-palette/700
        #unused: yellow #ffc425 blue #00aedb
        if tag_type == 'error':
            tag_color = '#d11141'  #red       
        elif tag_type == 'feedback':
            tag_color = '#00b159'  #green
        elif tag_type == 'warning':
            tag_color = '#f37735'  #orange
        else:
            tag_color = '#555555' #gray
        return tag_color

        
    def add_message(self, message):
        start_code, end_code = self.html.rsplit("</tr>", 1)
        tmp_str = start_code + "</tr><tr><td style ='padding-top: 10px'><p>{0}</p></td></tr>".format(message)
        tmp_str += end_code
        self.html = tmp_str
        
    def add_tag(self, tag_type = '', tag_str = ''):
        start_code, end_code = self.html.rsplit('<th></th>', 1)
        tmp_str = start_code + """<th><div style= 'border-radius: {0}; 
                                padding: 1px; padding-right: 5px; padding-left: 5px; text-align: left; 
                                background-color: {1}; color: {2}; margin-right: 2px'><h5>{3}</h5></div></th>
                                <th></th>""".format(self.tag_r, self.__set_tag_color__(tag_type), self.tag_text_color, tag_str)
        tmp_str += end_code
        self.html = tmp_str
    