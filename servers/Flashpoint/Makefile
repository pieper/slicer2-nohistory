# /home/mrtws/mrtmstr/DEVLSW is located on the mrt workstation in MRT suite
# The files are proprietary to GE.
EXTN_HOME = /home/mrtws/mrtmstr/DEVLSW
EXTN_OBJS = $(EXTN_HOME)/mror_image_buffer.o $(EXTN_HOME)/locator_client.o $(EXTN_HOME)/locator_common.o $(EXTN_HOME)/xformlib.a

LIBS   = -lnsl -lxview -lolgx -lX11 -L/usr/openwin/lib -lm
IFLAGS = -I$(EXTN_HOME) -I/usr/openwin/include
CFLAGS = -g $(IFLAGS)

all:spl_server

spl_server: spl_server.o $(EXTN_OBJS) Makefile
    $(CC) -o $@ $@.o ${CFLAGS} $(OBJS) $(EXTN_OBJS) $(LIBS)

spl_server.o: spl_server.c $(EXTN_HOME)/mror_imagebuf.h $(EXTN_HOME)/mror.h
    $(CC) ${CFLAGS} -c spl_server.c

clean:
    rm *.o
