import pypsa
import pandas as pd
#import matplotlib.pyplot as plt

# use 24 hour period for consideration
index = pd.date_range("2021-01-01 00:00","2021-01-02 23:00", freq="H")

# consumption pattern of BEV
bev_usage = pd.Series([0.]*7 + [0]*2 + [2.]*4 + [9.]*4 + [0.]*2 + [0.]*5 +[0.]*7 + 
                                    [0]*2 + [2.]*4 + [2.]*4 + [0.]*2 + [0.]*5, index)

# solar PV panel generation per unit of capacity
#pv_pu = pd.Series([0.]*7 + [0.2,0.4,0.6,0.75,0.85,0.9,0.85,0.75,0.6,0.4,0.2,0.1] + [0.]*5, index)
#Convert PV production to per unit
#P_pv1= P_pv1/0.160 # because it's in [KW] 
P_pv_pu_Test = pd.Series([0.]*7 + [0.2,0.4,0.6,0.75,0.85,0.9,0.85,0.75,0.6,0.4,0.2,0.1] + [0.]*5 +
                                        [0.]*7 + [0.2,0.4,0.3,0.2,0.5,0.1,0.4,0.4,0.6,0.4,0.2,0.1] + [0.]*5, index)
P_pv_pu_Test = P_pv_pu_Test/3.5


#_______________________________________

network = pypsa.Network()
network.set_snapshots(index)

network.add("Bus","House Connection",carrier="AC")


network.add("Generator","PV panel",
                    bus="House Connection",
                    p_nom = 15,
                    p_max_pu=P_pv_pu_Test,
                    p_min_pu=P_pv_pu_Test,
                    marginal_cost=0.019) # [Euro/KWh]


network.add("Load",
                    "House Loads",
                    bus="House Connection",
                    p_set=bev_usage)



network.add("StorageUnit",
                    "Home_Battery",
                    bus="House Connection",
                    p_nom=5,
                    p_min_pu = -1,
                    state_of_charge_initial=2,
                    cyclic_state_of_charge =False,
                    efficiency_store = 1,
                    efficiency_dispatch =1,
                    marginal_cost=0.25)

network.add("StorageUnit",
                    "Grid_Battery",
                    bus="House Connection",
                    p_nom=1000000,
                    p_min_pu = -1,
                    state_of_charge_initial=1000000/2,
                    cyclic_state_of_charge =False,
                    efficiency_store = 0.5,
                    efficiency_dispatch =0.5,
                    marginal_cost=100)


network.lopf(network.snapshots)
#network.lopf()

print(network.storage_units_t.state_of_charge['Home_Battery'])