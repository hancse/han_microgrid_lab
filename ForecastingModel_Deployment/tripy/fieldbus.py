class Fieldbus():
    def __init__(self, target, verbose = False):
        self.target = target
        self.verbose = verbose
        self.registers = self.target.perform_get('fieldbus', 'list').strip().split()[1:]

    def fieldbus_status(self):
        text = self.target.perform_get('fieldbus', 'status')
        # first line = number of registers
        lines = text.split('\n')[1:]
        values = {}
        for line in lines:
            lineValues = line.split()
            if len(lineValues) > 1:
                values[lineValues[1]] = lineValues[0]
        return values
        #add table print ==> tabulate

    def get_fieldbus_register(self, register):
        text = self.target.perform_get('fieldbus', 'get', {'register':register})
        if self.verbose == True:
            print('Fieldbus register {0} is equal to {1}'.format(register, text.strip()))
        return float(text.strip())

    def set_fieldbus_register(self, register, value):
        self.target.perform_get('fieldbus', 'set', {'register':register, 'value':str(value)})
        if self.verbose == True:
            print('Fieldbus register {0} set to {1}'.format(register, str(value)))
