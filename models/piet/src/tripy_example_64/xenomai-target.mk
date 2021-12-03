include variables.mk

MATLAB_ROOT     = $(MATLAB_ROOT_TGT)

include $(MATLAB_ROOT)/rtw/c/tools/unixtools.mk

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
ifeq ($(MULTITASKING), 1)
RTM_CC_OPTS += -DMULTITASKING
endif

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

ifndef OPT_OPTS
OPT_OPTS = $(DEFAULT_OPT_OPTS)
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

CC_OPTS = $(XENO_OPTS) $(ANSI_OPTS) $(EXT_CC_OPTS) $(RTM_CC_OPTS) $(OPTS) -O2 -fno-strict-aliasing $(OPT_OPTS)

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

