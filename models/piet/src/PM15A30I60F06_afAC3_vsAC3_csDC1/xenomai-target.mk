include variables.mk

CC = gcc
CXX = g++
LD = gcc

MATLAB_ROOT     = $(MATLAB_ROOT_TGT)

## wildcard is used to verify whether files exist

SRCS            = $(MODULES) $(wildcard $(S_FUNCTIONS)) $(wildcard $(patsubst %.c,%_data.c, $(filter %.c, $(S_FUNCTIONS))))
LINK_SRCS       = $(MODULES) $(S_FUNCTIONS) $(wildcard $(patsubst %.c,%_data.c, $(filter %.c, $(S_FUNCTIONS))))
USER_OBJS       = $(addsuffix .o, $(basename $(USER_SRCS)))
OBJS            = $(addsuffix .o, $(basename $(SRCS))) $(addsuffix .o, $(basename $(patsubst %.c,%_data.c, $(filter %.c, $(S_FUNCTIONS))))) $(USER_OBJS)
LOCAL_USER_OBJS = $(notdir $(USER_OBJS))
LINK_OBJS       = $(sort $(wildcard $(patsubst %.c,%_data.o, $(filter %.c, $(S_FUNCTIONS)))) $(addsuffix .o, $(basename $(LINK_SRCS))) $(LOCAL_USER_OBJS)) #sort to remove duplicates
SHARED_OBJS     = $(addsuffix .o, $(basename $(SHARED_SRC)))
SHARED_SRC      := $(wildcard $(SHARED_SRC))

HAS_KMGR_PKG = 0
ifeq ("$(shell dpkg -l | grep 3p-kmgr >/dev/null 2>&1 && echo 1)","1")
  HAS_KMGR_PKG = 1
endif

IS_TRIPHASE_LEGACY = 0
ifeq ("$(shell grep -e "jasper" /etc/apt/sources.list | grep -v "^\#" >/dev/null 2>&1 && echo 1)","1")
  IS_TRIPHASE_LEGACY = 1
endif

HAS_RTE1000D_PKG = 0
ifeq ("$(shell dpkg -l | grep lib3prte1000d >/dev/null 2>&1 && echo 1)","1")
  HAS_RTE1000D_PKG = 1
endif

HAS_LIB3PFC_PKG = 0
ifeq ("$(shell dpkg -l | grep lib3pfc >/dev/null 2>&1 && echo 1)","1")
  HAS_LIB3PFC_PKG = 1
endif

HAS_LIB3PCIPC_PKG = 0
ifeq ("$(shell dpkg -l | grep lib3pcipc >/dev/null 2>&1 && echo 1)","1")
  HAS_LIB3PCIPC_PKG = 1
endif

IS_LIB3PFC_LEGACY = 2
ifeq ($(HAS_LIB3PFC_PKG),1)
  ifeq ("$(shell dpkg -s lib3pfc | sed -n 's/^Version: //p' | sed s'/\([0-9]*\).*/\1/')","1")
    IS_LIB3PFC_LEGACY = 1
  endif
endif	

USE_LIB3PMATH = 0
ifeq ($(strip $(TP_MATH)), 1)
  ifeq ("$(shell dpkg -l | grep lib3pgon >/dev/null 2>&1 && echo 1)","1")
    USE_LIB3PMATH = 1
  else
    $(error ERROR Build fails for '$(MODEL)'. Set to use Triphase mathematical library 'lib3pgon', however it is not installed)
  endif
endif

MATH_OPTS := -ffast-math
ifeq ("$(FLOAT_MATH_MODE)","x87")
  MATH_OPTS += -mfpmath=387 
else ifeq ("$(FLOAT_MATH_MODE)", "SSE")
  MATH_OPTS += -mfpmath=sse 
  MATH_OPTS += -msse2
endif

ifeq ("$(TP_AMESIM_ROOT)","")
TP_AMESIM_CFLAGS =
TP_AMESIM_INCLUDES =
TP_AMESIM_OBJS = 
TP_AMESIM_LIBS = 
else
TP_AMESIM_CFLAGS = -DAMESIMULINK -DAMERT
TP_AMESIM_INCLUDES = -I$(TP_AMESIM_ROOT)/interfaces/simulink -I$(TP_AMESIM_ROOT)/lib
TP_AMESIM_OBJS = $(addprefix $(TP_AMESIM_ROOT)/submodels/lnx/,$(addsuffix .o, $(TP_AMESIM_SUBMODELS)))
TP_AMESIM_LIBS = $(shell ls $(TP_AMESIM_ROOT)/*/lib/lnx/*.a $(TP_AMESIM_ROOT)/lib/lnx/*.a)
endif

MATLAB_INCLUDES = \
        -I$(MATLAB_ROOT)/toolbox/dspblks/include \
        -I$(MATLAB_ROOT)/simulink/include \
        -I$(MATLAB_ROOT)/extern/include \
        -I$(MATLAB_ROOT)/rtw/c/src \
        -I$(MATLAB_ROOT)/rtw/c/xenomai \
        -I$(MATLAB_ROOT)/rtw/c/libsrc \
        -I$(MATLAB_ROOT)/rtw/c/src/ext_mode/common \
        -I$(MATLAB_ROOT)/rtw/c/src/rtiostream/rtiostreamtcpip \
        -I$(MATLAB_ROOT)/toolbox/coder/rtiostream/src/utils

TRIPHASE_INCLUDES = -I /usr/3p/include

ifeq ($(HAS_KMGR_PKG), 1)
  TRIPHASE_INCLUDES += ${shell pkg-config --cflags 3pkmgr --silence-errors}
endif

TRIPHASE_INCLUDES += ${shell libgcrypt-config --cflags} ${shell pkg-config --cflags lib3putils --silence-errors}

ifeq ($(TP_EXT_MODE),1)
  TP_EXT_MODE_ACTIVE = 1
endif
ifeq ($(TP_EXT_MODE_LIGHT),1)
  TP_EXT_MODE_ACTIVE = 1
endif

ifeq ($(TP_EXT_MODE_ACTIVE),1)
  ifeq ($(IS_TRIPHASE_LEGACY), 1)
    TRIPHASE_INCLUDES += ${shell pkg-config --cflags 3pextmode --silence-errors}
  else
    TRIPHASE_INCLUDES += ${shell pkg-config --cflags lib3pxmode --silence-errors}
  endif
endif

ifeq ($(HAS_RTE1000D_PKG), 1)
  TRIPHASE_INCLUDES += ${shell pkg-config --cflags lib3prte1000d --silence-errors}
endif

ifeq ($(HAS_LIB3PFC_PKG), 1)
  TRIPHASE_INCLUDES += ${shell pkg-config --cflags lib3pfc --silence-errors}
endif

ifdef EXTRA_MODEL_CONFIG_FILE
  ifneq ("$(wildcard ${EXTRA_MODEL_CONFIG_FILE})", "")
    buffer_bus_names:= $(sort $(strip $(shell grep "^[[:space:]]*BusName[[:space:]]*=" ${EXTRA_MODEL_CONFIG_FILE} | grep -o "[_[:alnum:]-]*[[:space:]]*$$")))
    port_names:= $(sort $(strip $(shell grep "^[[:space:]]*PortName[[:space:]]*=" ${EXTRA_MODEL_CONFIG_FILE} | grep -o "[_[:alnum:]-]*[[:space:]]*$$")))
  endif
endif
ifeq ($(HAS_LIB3PCIPC_PKG), 1)
  ifdef buffer_bus_names
    TRIPHASE_INCLUDES += ${shell pkg-config --cflags lib3pcipc --silence-errors}
    ifdef CIPC_CONFIG_FILE
      port_names_config_buffer:= $(sort $(strip $(shell grep -o "^[[:space:]]*.*\.buffer_name" ${CIPC_CONFIG_FILE})))
      port_names_config_order:= $(sort $(strip $(shell grep -o "^[[:space:]]*.*\.buffer_order" ${CIPC_CONFIG_FILE})))
      $(foreach iport, $(port_names), $(if $(findstring $(iport),$(port_names_config_buffer)),,$(error ERROR model port name $(iport) not consistent with port name in $(CIPC_CONFIG_FILE) when mapping to buffer)))
      $(foreach iport, $(port_names), $(if $(findstring $(iport),$(port_names_config_order)),,$(warning WARNING model port name $(iport) not consistent with port name in $(CIPC_CONFIG_FILE) when setting buffer order)))
    else
      $(error ERROR No CIPC buffer configuration file found with name: $(MODEL)_config)
    endif
    ifeq ($(strip $(CIPC_PACKED)), 1)
        ifneq ("$(wildcard $(addprefix ${MODEL},_types.h))", "")
          ifneq ($(shell grep '^\#pragma[[:space:]*]pack' $(addprefix ${MODEL},_types.h) > /dev/null; echo $$?), 0)
              # Get all defined structs within the file
            all_structs:=$(strip $(shell sed -n '/^typedef[[:space:]*]struct[[:space:]*]{/{ :x ; n ; /^[^}]/bx ; P}' $(addprefix ${MODEL},_types.h) | grep -o '[-[:alnum:]_]*')) 
            # Get all structs that are not directly listed from cipc_buf_read.tlc
            non_buffer_structs:=$(strip $(foreach bus, ${all_structs}, $(if $(findstring $(bus),$(buffer_bus_names)),,$(bus))))
            # Define function to look for a toplevel struct and then check for a top -1 level struct.
            # 1 is the toplevel struct (a buffer) struct
            # 2 is the top-1 level struct (a non-buffer) struct
            # 3 is the file name on which sed operates
            # Returns the nested struct by name if found
            search_nested=$(shell sed -n '/^typedef[[:space:]*]struct[[:space:]*]{/{ :x ; H ; n ; s/^}/}/;Tx ; /$(1)\;/by ; z ; x ; d ; :y ; x ; /[[:space:]*]$(2)[[:space:]*]/p}' $(3) | grep -o '$(2)')
            # First iteration
            buffer_bus_names+=$(sort $(strip $(foreach ibus, $(buffer_bus_names), $(foreach jbus, $(non_buffer_structs), $(call search_nested,$(ibus),$(jbus),$(addprefix ${MODEL},_types.h))))))
            non_buffer_structs:=$(strip $(foreach bus, ${all_structs}, $(if $(findstring $(bus),$(buffer_bus_names)),,$(bus))))
            # Second iteration
            buffer_bus_names+=$(sort $(strip $(foreach ibus, $(buffer_bus_names), $(foreach jbus, $(non_buffer_structs), $(call search_nested,$(ibus),$(jbus),$(addprefix ${MODEL},_types.h))))))
            non_buffer_structs:=$(strip $(foreach bus, ${all_structs}, $(if $(findstring $(bus),$(buffer_bus_names)),,$(bus))))
            # Third iteration
            buffer_bus_names+=$(sort $(strip $(foreach ibus, $(buffer_bus_names), $(foreach jbus, $(non_buffer_structs), $(call search_nested,$(ibus),$(jbus),$(addprefix ${MODEL},_types.h))))))
            non_buffer_structs:=$(strip $(foreach bus, ${all_structs}, $(if $(findstring $(bus),$(buffer_bus_names)),,$(bus))))
            # Fourth iteration
            buffer_bus_names+=$(sort $(strip $(foreach ibus, $(buffer_bus_names), $(foreach jbus, $(non_buffer_structs), $(call search_nested,$(ibus),$(jbus),$(addprefix ${MODEL},_types.h))))))
            non_buffer_structs:=$(strip $(foreach bus, ${all_structs}, $(if $(findstring $(bus),$(buffer_bus_names)),,$(bus))))
            # Fifth iteration
            buffer_bus_names+=$(sort $(strip $(foreach ibus, $(buffer_bus_names), $(foreach jbus, $(non_buffer_structs), $(call search_nested,$(ibus),$(jbus),$(addprefix ${MODEL},_types.h))))))
            # Place pragmas around all structs used with cipc buffers
            $(foreach bus, $(buffer_bus_names), $(shell sed -i '/^}[[:space:]*]$(bus)\;/a#pragma pack(pop)' $(addprefix ${MODEL},_types.h)))
            $(foreach bus, $(buffer_bus_names), $(shell sed -i '/^#define[[:space:]*][-[:alnum:]_]*$(bus)_[^[:alnum:]]*/a#pragma pack(push, 1)' $(addprefix ${MODEL},_types.h))) 
            $(info INFO Packed struct alignment set for: ${buffer_bus_names})
            $(info WARNING Only 5 levels of nested structures are currently supported)
          endif
        endif
    endif
  endif
endif

ifeq ($(USE_LIB3PMATH), 1)
  TRIPHASE_INCLUDES += ${shell pkg-config --cflags lib3pgon --silence-errors}
endif

SHARED_INCLUDES =
ifneq ($(SHARED_SRC_DIR),)
SHARED_INCLUDES = -I$(SHARED_SRC_DIR)
endif

INCLUDES = -I. $(MATLAB_INCLUDES) $(ADD_INCLUDES) $(USER_INCLUDES) \
        $(INSTRUMENT_INCLUDES)  $(MODELREF_INC_PATH) $(SHARED_INCLUDES) \
        $(TRIPHASE_INCLUDES) $(TP_AMESIM_INCLUDES)

ifeq ($(EXT_MODE),1)
  EXT_CC_OPTS = -DEXT_MODE -D$(COMPUTER) #-DVERBOSE
  EXT_LIB =
  ifneq (, $(findstring $(RELEASE_VERSION_SHORT), "14 R2006a R2006b R2007a R2007b"))
    EXT_SRC = ext_svr.c updown.c ext_work.c ext_svr_tcpip_transport.c
  else
    EXT_SRC = ext_svr.c updown.c ext_work.c rtiostream_tcpip.c rtiostream_interface.c
    ifneq (,$(wildcard $(MATLAB_ROOT)/toolbox/coder/rtiostream/src/utils/rtiostream_utils.c)) # from R2013a
      EXT_SRC += rtiostream_utils.c
    endif
  endif
  ifeq ($(EXTMODE_STATIC),1)
    EXT_SRC             += mem_mgr.c
    EXT_CC_OPTS         += -DEXTMODE_STATIC -DEXTMODE_STATIC_SIZE=$(EXTMODE_STATIC_SIZE)
  endif
else
  EXT_CC_OPTS =
  EXT_SRC =
endif

ifeq ($(TP_EXT_MODE),1)
  EXT_CC_OPTS += -DTP_EXT_MODE
  EXT_SRC += tp_ext_work.c tp_capi.c
endif

ifeq ($(TP_EXT_MODE_LIGHT),1)
  EXT_CC_OPTS += -DTP_EXT_MODE_LIGHT
  EXT_SRC += tp_ext_work.c tp_capi.c
endif

RTM_CC_OPTS = -DUSE_RTMODEL

## Mapping of tasks to core
## BEGIN
list_rt_cores := $(strip $(shell grep -o "isolcpus=[[:space:]]*[[:digit:],*]*" /proc/cmdline | grep -o "[[:digit:]]" | tr '\n' ' '))

# Get list of rt_cores
ifeq ($(strip $(list_rt_cores)),)
  $(warning WARNING There are no isolated cores for realtime tasks. Expect degraded performance!)  
  ifeq ($(shell hash nproc 2>/dev/null; echo $$?), 0)
    nr_cores := $(shell nproc --all)
    list_rt_cores := $(shell seq 1 $(shell echo $$(( ${nr_cores} -1 ))))
  else
    $(warning WARNING Unable to detect number of cores, assuming 2 cores)
    list_rt_cores := 1 #assume two core machine, only use cpu 1
  endif
endif
$(info INFO Available CPU cores: ${list_rt_cores})

# Function to clip user input
clip_core_upper = $(foreach opt, $(strip $(1)), $(shell if [ $(opt) -gt $(2) ]; then echo $(2); else echo $(opt);fi))
clip_core_lower = $(foreach opt, $(strip $(1)), $(shell if [ $(opt) -lt $(2) ]; then echo $(2); else echo $(opt);fi))

# Check for empty realtime task to core mapping
ifeq ($(strip $(AUTO_TASK_TO_CORE_MAPPING)), 0)
  ifeq ($(strip ${TASK_TO_CORE_MAPPING}),)
    $(warning WARNING Realtime taks to core mapping was empty, defaulting to core $(firstword ${list_rt_cores}))
    TASK_TO_CORE_MAPPING := $(firstword $(strip $(list_rt_cores)))
  else #if not empty bound entries
    TASK_TO_CORE_MAPPING := $(call clip_core_upper,$(TASK_TO_CORE_MAPPING),$(lastword $(list_rt_cores)))
    TASK_TO_CORE_MAPPING := $(call clip_core_lower,$(TASK_TO_CORE_MAPPING),$(firstword $(list_rt_cores)))
  endif
endif

# Map Tasks to cores
RTM_CC_OPTS += -DMAIN_TASK_AFF=$(firstword ${list_rt_cores})

ifeq ($(shell test ${NUMST} -gt 1; echo $$?), 0) # Multitasking
  RTM_CC_OPTS += -DMULTITASKING
  list_numst := $(shell seq 0 $(shell echo $$(( ${NUMST} -1 ))))
  ifeq ($(strip $(AUTO_TASK_TO_CORE_MAPPING)), 1)
    TMP_RTM_OPTS1 := $(foreach numst, $(list_numst), $(subst NUMST,$(numst),-DTASK_NUMST_AFF=RT_CORE))
    #map ith task to the ith core
    TMP_RTM_OPTS2 := $(foreach rt_core, ${list_rt_cores}, $(subst RT_CORE,${rt_core},$(word ${rt_core},${TMP_RTM_OPTS1})))
    count := $(words ${TMP_RTM_OPTS2})
    count2 := $(shell echo $$(( ${count} + 1 )))
    #map the remaining tasks to the last core of list_rt_cores
    TMP_RTM_OPTS3 := $(foreach opts, $(wordlist ${count2}, $(words ${TMP_RTM_OPTS1}), ${TMP_RTM_OPTS1}), $(subst RT_CORE,$(lastword ${list_rt_cores}),${opts}))
    RTM_CC_OPTS += ${TMP_RTM_OPTS2} ${TMP_RTM_OPTS3}
  else
    TMP_RTM_OPTS1 := $(foreach numst, $(list_numst), $(subst NUMST,$(numst),-DTASK_NUMST_AFF=))
    ifeq ("${NUMST}","$(words $(strip ${TASK_TO_CORE_MAPPING}))")
      TMP_RTM_OPTS2 := $(join $(TMP_RTM_OPTS1), $(strip ${TASK_TO_CORE_MAPPING}))
      RTM_CC_OPTS += ${TMP_RTM_OPTS2}
    else
      $(info INFO The number of model sampletimes ${NUMST} does not match the number of task-to-core-mappings $(words $(strip ${TASK_TO_CORE_MAPPING})))
      $(info INFO Mapping the unmapped realtime tasks to $(lastword $(strip ${TASK_TO_CORE_MAPPING}))) 
      EXTENDED_TASK_TO_CORE_MAPPING := $(foreach opt, $(wordlist $(words $(strip ${TASK_TO_CORE_MAPPING})), $(shell echo $$(( ${NUMST} -1 ))), $(shell seq 0 ${NUMST})), $(lastword $(strip ${TASK_TO_CORE_MAPPING}))) #FIXME: there must be an easier way
      RTM_CC_OPTS += $(join $(TMP_RTM_OPTS1), $(strip ${TASK_TO_CORE_MAPPING}) ${EXTENDED_TASK_TO_CORE_MAPPING})
    endif
  endif
else ifeq ($(shell test ${NUMST} -eq 1; echo $$?), 0) # Single task
  ifeq ($(strip $(AUTO_TASK_TO_CORE_MAPPING)), 1)
    RTM_CC_OPTS += $(subst RT_CORE,$(firstword ${list_rt_cores}), -DTASK_0_AFF=RT_CORE)
  else
    RTM_CC_OPTS += $(subst RT_CORE,$(firstword $(strip ${TASK_TO_CORE_MAPPING})), -DTASK_0_AFF=RT_CORE)
  endif
endif
$(info INFO Task to core mapping: $(RTM_CC_OPTS))
## END

## Mapping of external mode task to a core
## BEGIN
ifeq ($(strip $(AUTO_EXTMODE_TASK_TO_CORE_MAPPING)), 1)
  TMP_EXT_MODE_OPTS += $(subst RT_CORE,$(firstword $(strip ${list_rt_cores})), -DEXT_MODE_AFF=RT_CORE)
else
  ifeq ($(strip ${EXTMODE_TASK_TO_CORE_MAPPING}),)
    $(warning WARNING External mode taks to core mapping was empty, defaulting to core $(firstword ${list_rt_cores}))
    EXTMODE_TASK_TO_CORE_MAPPING := $(firstword $(strip $(list_rt_cores)))
  else
    EXTMODE_TASK_TO_CORE_MAPPING := $(call clip_core_upper,$(EXTMODE_TASK_TO_CORE_MAPPING),$(lastword $(list_rt_cores)))
    EXTMODE_TASK_TO_CORE_MAPPING := $(call clip_core_lower,$(EXTMODE_TASK_TO_CORE_MAPPING),0)
  endif
    TMP_EXT_MODE_OPTS += $(subst RT_CORE,$(firstword $(strip ${EXTMODE_TASK_TO_CORE_MAPPING})),-DEXT_MODE_AFF=RT_CORE)
endif
$(info INFO External mode task to core mapping: $(TMP_EXT_MODE_OPTS))
RTM_CC_OPTS += ${TMP_EXT_MODE_OPTS}
## END

RTM_CC_OPTS += -DBASE_PRIORITY=$(BASE_PRIORITY) -DRT_STACK_SIZE=$(RT_STACK_SIZE)

ifeq ($(KEEP_TET_INFO), 1)
RTM_CC_OPTS += -DKEEP_TET_INFO
endif

ifeq ($(DOUBLE_BUFFER_PARAMETERS), 1)
RTM_CC_OPTS += -DDOUBLE_BUFFER_PARAMETERS
endif

ifeq ($(STOPONOVERRUN), 1)
RTM_CC_OPTS += -DSTOPONOVERRUN
endif

ifeq ($(HAS_KMGR_PKG), 1)
RTM_CC_OPTS += -DKMGR_FOUND
endif

ifeq ($(IS_TRIPHASE_LEGACY), 1)
RTM_CC_OPTS += -DTRIPHASE_LEGACY
endif

ifeq ($(CODE_FORMAT), RealTimeMalloc)
RTM_CC_OPTS += -DRT_MALLOC
endif

ifeq ($(IS_LIB3PFC_LEGACY), 1)
RTM_CC_OPTS += -DLIB3PFC_LEGACY
endif

XENO_VERSION = $(shell xeno-config --version | cut -d '.' -f 1,2)
ifeq ($(XENO_VERSION), 2.4)
XENO_OPTS = $(shell xeno-config --xeno-cflags)
else
XENO_OPTS = $(shell xeno-config --skin=native --cflags) -DXENO_26=1
endif
ifeq ($(ENABLE_TIMER), 0)
XENO_OPTS += -DRTDM
endif

# Override ANSI_OPTS based on platform if needed, without being -pedantic...
ifeq ($(TGT_FCN_LIB),ISO_C)
  ANSI_OPTS = -std=c99
else
  ifeq ($(TGT_FCN_LIB),GNU)
    ANSI_OPTS = -std=gnu99
  else
    ifeq ("$(TGT_FCN_LIB)","GNU99 (GNU)")
      ANSI_OPTS = -std=gnu99
    else
      ifneq ($(NON_ANSI_TRIG_FCN), 1)
         ANSI_OPTS = -ansi
      endif
    endif
  endif
endif

CC_OPTS = $(XENO_OPTS) $(ANSI_OPTS) $(EXT_CC_OPTS) $(RTM_CC_OPTS) $(OPTS) -O2 -march=native -fno-strict-aliasing -ffloat-store $(OPT_OPTS) $(MATH_OPTS)

EXTRA_ARCHIVES = 

CPP_REQ_DEFINES = -DMODEL=$(MODEL) -DRELEASE_VERSION_SHORT=$(RELEASE_VERSION_SHORT) -DRT -DNUMST=$(NUMST) \
                  -DTID01EQ=$(TID01EQ) -DNCSTATES=$(NCSTATES) -DUNIX \
                  -DHAVESTDIO

CFLAGS          = $(CC_OPTS) $(CPP_REQ_DEFINES) $(INCLUDES) $(TP_AMESIM_CFLAGS)
CPPFLAGS        = $(CPP_OPTS) $(CC_OPTS) $(CPP_REQ_DEFINES) $(INCLUDES)
ifeq ($(XENO_VERSION), 2.4)
LDFLAGS         = $(shell xeno-config --xeno-ldflags) -lrtdm $(LD_OPTS)
else
LDFLAGS         = $(shell xeno-config --skin=native --ldflags) -lrtdm $(LD_OPTS)
endif

ifeq ($(TP_EXT_MODE_ACTIVE),1)
  ifeq ($(IS_TRIPHASE_LEGACY), 1)
    LDFLAGS         += ${shell pkg-config --libs 3pextmode --silence-errors}
  else
    LDFLAGS         += ${shell pkg-config --libs lib3pxmode --silence-errors}
  endif
endif

ifeq ($(HAS_KMGR_PKG), 1)
  LDFLAGS         += ${shell pkg-config --libs 3pkmgr --silence-errors}
endif

LDFLAGS         += ${shell libgcrypt-config --libs} ${shell pkg-config --libs lib3putils --silence-errors}

ifeq ($(HAS_RTE1000D_PKG), 1)
  LDFLAGS         += ${shell pkg-config --libs lib3prte1000d --silence-errors}
endif

ifeq ($(HAS_LIB3PFC_PKG), 1)
  LDFLAGS         += ${shell pkg-config --libs lib3pfc --silence-errors}
endif

ifeq ($(HAS_LIB3PCIPC_PKG), 1)
  LDFLAGS         += ${shell pkg-config --libs lib3pcipc --silence-errors}
endif

ifeq ($(USE_LIB3PMATH), 1)
  ifneq ("$(shell grep -n "intercept_3pgon.h" $(MODEL).h >/dev/null 2>&1 && echo 1)", "1")
    ifeq ("$(shell file $(MODEL).h | grep CRLF -o >/dev/null 2>&1 && echo 1)", "1")
      $(shell dos2unix $(MODEL).h)
    endif
    $(shell sed -i '/#include[[:space:]]*[\t]*<math.h>/i#include "intercept_3pgon.h"' $(MODEL).h)
    $(shell sed -i '/#include "intercept_3pgon.h"/a#include "3pgon.h"' $(MODEL).h)
  endif
  LDFLAGS         += ${shell pkg-config --libs lib3pgon --silence-errors}
endif

SYSLIBS = $(EXT_LIB) -lnative -lm

LIBS = $(PRECOMP_LIBS) $(REGULAR_LIBS) $(INSTRUMENT_LIBS) $(S_FUNCTIONS_LIBS)

ifneq ($(findstring .cpp,$(suffix $(LINK_SRCS), $(USER_SRCS))),)
LD = $(CPP)
endif

ifeq ($(MODELREF_TARGET_TYPE), NONE)
    PRODUCT            = $(MODEL)
    BIN_SETTING        = $(LD) -o $(PRODUCT) $(SYSLIBS)
    BUILD_PRODUCT_TYPE = "executable"
    LINK_SRCS         += $(MODEL).c xeno_main.c rt_sim.c $(EXT_SRC) $(SOLVER)
    SRCS              += $(MODEL).c xeno_main.c rt_sim.c $(EXT_SRC) $(SOLVER)
else
    # Model reference rtw target
    PRODUCT            = $(MODELLIB)
    BUILD_PRODUCT_TYPE = "library"
endif

GCC_TEST_CMD  := echo
GCC_TEST_OUT  := > /dev/null
ifeq ($(DO_GCC_TEST), 1)
  GCC_TEST := gcc -c -o /dev/null $(GCC_WARN_OPTS_MAX) $(CPP_REQ_DEFINES) \
                                     $(INCLUDES)
  GCC_TEST_CMD := echo; echo "\#\#\# GCC_TEST $(GCC_TEST) $<"; $(GCC_TEST)
  GCC_TEST_OUT := ; echo
endif

GCC_WALL_FLAG     :=
GCC_WALL_FLAG_MAX :=
ifeq ($(COMPUTER), GLNX86)
ifeq ($(WARN_ON_GLNX), 1)
  GCC_WALL_FLAG     := $(GCC_WARN_OPTS)
  GCC_WALL_FLAG_MAX := $(GCC_WARN_OPTS_MAX)
endif
endif

all : $(PRODUCT)

rtw_sfunc_fix: $(MODEL)_private.h $(MODEL).c
	@sed -e 's/^[ \t]*\#include "[a-zA-Z0-9_]*_sfcn_rtw\//\#include "/' $(MODEL)_private.h > tmp.h; mv tmp.h $(MODEL)_private.h
	@sed -e 's/^[ \t]*\#include "[a-zA-Z0-9_]*_sfcn_rtw\//\#include "/' $(MODEL).c > tmp.c; mv tmp.c $(MODEL).c

ifeq ($(MODELREF_TARGET_TYPE),NONE)
$(PRODUCT) : rtw_sfunc_fix $(OBJS) $(SHARED_LIB) $(LIBS) $(MODELREF_LINK_LIBS) $(EXTRA_ARCHIVES)
	$(BIN_SETTING) $(LINK_OBJS) $(LDFLAGS) $(MODELREF_LINK_LIBS) $(LIBS) $(SHARED_LIB) $(EXTRA_ARCHIVES) $(TP_AMESIM_OBJS) $(TP_AMESIM_LIBS)
	@if [ ! -f /home/triphase/src/tpdev.txt ]; then rm -f *.c *.cpp *.h *.hpp *.o; fi
	@echo "### Created $(BUILD_PRODUCT_TYPE): $@"
else
$(PRODUCT) : rtw_sfunc_fix $(OBJS) $(SHARED_LIB) $(LIBS)
	@rm -f $(MODELLIB)
	@ar ruvs $(MODELLIB) $(wildcard $(addsuffix .o, $(basename $(LINK_SRCS)))) $(LOCAL_USER_OBJS)
	@if [ ! -f /home/triphase/src/tpdev.txt ]; then rm -f *.c *.cpp *.h *.hpp *.o; fi
	@echo "### Created $(MODELLIB)"
	@echo "### Created $(BUILD_PRODUCT_TYPE): $@"
endif

%.o : %.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG) $<

%.o : %.cpp
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CPP) -c $(CPPFLAGS) $(GCC_WALL_FLAG) $<

%.o : $(MATLAB_ROOT)/rtw/c/xenomai/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/src/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/src/ext_mode/common/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/src/ext_mode/tcpip/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/src/rtiostream/rtiostreamtcpip/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/src/rtiostream/utils/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/toolbox/coder/rtiostream/src/utils/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/src/ext_mode/custom/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/rtw/c/libsrc/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : /home/triphase/src/rt_signal_server/src/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : /home/triphase/src/3p_ext_mode/src/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/simulink/src/%.c
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CC) -c $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

%.o : $(MATLAB_ROOT)/simulink/src/%.cpp
	@$(GCC_TEST_CMD) $< $(GCC_TEST_OUT)
	$(CPP) -c $(CPPFLAGS) $<

#----------------------------- Dependencies ------------------------------------

$(OBJS) : xenomai-target.mk variables.mk rtw_proj.tmw

$(SHARED_OBJS) : $(SHARED_BIN_DIR)/%.o : $(SHARED_SRC_DIR)/%.c
	$(CC) -c -o $(SHARED_BIN_DIR)/$(@F) $(CFLAGS) $(GCC_WALL_FLAG_MAX) $<

$(SHARED_LIB) : $(SHARED_OBJS)
	@echo "### Creating $@ "
	@ar ruvs $@ $(SHARED_OBJS)
	@echo "### $@ Created  "

#--------- Miscellaneous rules to purge and clean ------------

purge : clean
	@echo "### Deleting the generated source code for $(MODEL)"
	@\rm -f $(MODEL).c $(MODEL).h $(MODEL)_types.h $(MODEL)_data.c \
	        $(MODEL)_private.h $(MODEL).rtw $(MODULES) rtw_proj.tmw \
		xenomai-target.mk variables.mk

clean :
	@echo "### Deleting the objects and $(PRODUCT)"
	@\rm -f $(wildcard $(addsuffix .o, $(basename $(LINK_SRCS)))) $(LOCAL_USER_OBJS) $(PRODUCT)

