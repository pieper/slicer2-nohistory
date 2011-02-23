#define STHDR_START     6*256
#define SEHDR_START     8*256
#define IHDR_START      10*256

typedef struct {
    char    field[4];
} MY_DG_FLOAT;
/***************************
typedef struct {
        unsigned        sign : 1;
        unsigned        exponent : 7;
        unsigned        mantissa : 24;
} MY_DG_FLOAT;
***************************/


typedef struct {
    char    sthdr_id[14];
    char    sthdr_rev[8];
    short    sthdr_blks;
    char    sthdr_crtrp[32];
    short    sthdr_crtrt;
    char    sthdr_rawnm[5];
    char    sthdr_skip1;
    char    sthdr_stnum[5];
    char    sthdr_skip11;
    char    sthdr_rawid[3];        /* Raw Data System ID*/
    char    sthdr_skip2;
    char    sthdr_sgenid[3];    /* System Generation ID*/
    char    sthdr_skip3;
    char    sthdr_date[9];        /* Date of Study (ascii*/
    char    sthdr_skip4;
    short    sthdr_idate[3];        /* Date of Study (integer*/
    char    sthdr_time[8];        /* Time of Study (ascii*/
    short    sthdr_itime[3];        /* Time of Study (integer*/
    char    sthdr_pnm[32];        /* Patient Name*/
    char    sthdr_pid[12];        /* Patient ID*/
    char    sthdr_pidtmp[4];    /* Patient ID padding for future exp.*/
    char    sthdr_age[3];        /* Age of patient*/
    char    sthdr_skip5;
    char    sthdr_sex[1];        /* Sex of patient*/
    char    sthdr_skip6;
    short    sthdr_wght[2];        /* Weight of the patient in grams*/
    char    sthdr_rfr[32];        /* Refered by*/
    char    sthdr_dgn[32];        /* Diagnostician*/
    char    sthdr_op[32];        /* Operator*/
    char    sthdr_desc[60];        /* Description*/
    char    sthdr_hist[120];    /* History*/
    short    sthdr_stime[2];        /* Creation time in seconds.*/
    char    sthdr_hosp[32];        /* Hospital name*/
    char    sthdr_rsrv1[34];    /* GE NMR Reserved Area*/
    short    sthdr_rsrv2[255];    /* GE NMR Reserved Area*/
    short    sthdr_check;        /* Study Header Checksum*/
} STUDY;

typedef struct {
    char    sehdr_id[14];        /* Series Header Identifier*/
    char    sehdr_rev[8];        /* Series Header Revision Number*/
    short    sehdr_blks;        /* Number of Series Header Blocks*/
    char    sehdr_crtrp[32];    /* Series Header Creator (Proc*/
    short    sehdr_crtrt;        /* Series Header Creator (Task*/
    char    sehdr_rawnm[3];        /* Original Series Number*/
    char    sehdr_skip1;
    char    sehdr_sernum[3];    /* Series Number*/
    char    sehdr_skip2;
    char    sehdr_rawid[3];        /* Raw Data System ID*/
    char    sehdr_skip3;
    char    sehdr_sgenid[3];    /* System Generation ID*/
    char    sehdr_skip4;
    char    sehdr_date[9];        /* Date of series (ascii*/
    char    sehdr_skip5;
    short    sehdr_idate[3];        /* Date of series (integer*/
    char    sehdr_time[8];        /* Time of Series (ascii*/
    short    sehdr_itime[3];        /* Time of Series (integer*/
    char    sehdr_desc[120];    /* Series Description*/
    short    sehdr_type;        /* Series Type*/
    short    sehdr_ctype;        /* Coil Type*/
    char    sehdr_cname[16];    /* Coil Name*/
    char    sehdr_cntrdesc[32];    /* Contrast Description*/
    short    sehdr_ptype;        /* Plane Type*/
    char    sehdr_pname[16];    /* Plane Name*/
    short    sehdr_imode;        /* Image Mode*/
    short    sehdr_fstren;        /* Magnetic Field Strength*/
    short    sehdr_pseq;        /* Pulse Sequence*/
    short    sehdr_psstype;        /* Pulse sequence subtype*/
    MY_DG_FLOAT    sehdr_fov;        /* Field of view*/
    MY_DG_FLOAT    sehdr_center[3];    /* Center*/
    short    sehdr_orien;        /* Orientation*/
    short    sehdr_pos;        /* Position*/
    char    sehdr_anref[32];    /* Longitudinal Anotomical Reference*/
    char    sehdr_vanref[32];    /* Vertical Anotomical Reference*/
    MY_DG_FLOAT    sehdr_verlan;        /* Vertical Landmark*/
    MY_DG_FLOAT    sehdr_horlan;        /* Horizontal Landmark*/
    MY_DG_FLOAT    sehdr_tblloc;        /* Physical Table Location*/
    short    sehdr_smatrix[2];    /* Scan Matrix*/
    short    sehdr_imatrix;        /* Image Matrix*/
    short    sehdr_ialloc;        /* No. of Images Allocated*/
    short    sehdr_gtyp;        /* Gating Type*/
    short    sehdr_rsrv1[52];    /* GE NMR Reserved*/
    short    sehdr_rsrv2[255];    /* GE NMR Reserved*/
    short    sehdr_check;        /* Checksum for Series Header*/
} SERIES;

typedef struct {
    char ihdr_id[14];        /* Image Header Identifier*/
    char ihdr_rev[8];        /* Image Header Revision Number*/
    short ihdr_blks;        /* Number of Image Header Blocks*/
    char ihdr_crtrp[32];        /* Image Header Creator (Proc*/
    short ihdr_crtrt;        /* Image Header Creator (Task*/
    char ihdr_date[9];        /* Image Creation Date (ascii*/
    char ihdr_skip1;
    short ihdr_idate[3];        /* Image Creation Date (integer*/
    char ihdr_time[8];        /* Image Creation Time (ascii*/
    short ihdr_itime[3];        /* Image Creation Time (integer*/
    char ihdr_imnum[3];        /* Image Number*/
    char ihdr_skip2;
    char ihdr_sernm[3];        /* Series Number of Image*/
    char ihdr_skip21;
    char ihdr_rawid[3];        /* Raw Data System ID*/
    char ihdr_skip3;
    char ihdr_sgenid[3];        /* System Generation ID*/
    char ihdr_skip4;
    MY_DG_FLOAT ihdr_strtx;        /* Start Location X, Right min*/
    MY_DG_FLOAT ihdr_endx;        /* End Location X, Right max*/
    MY_DG_FLOAT ihdr_strty;        /* Start Location Y, Anterior min*/
    MY_DG_FLOAT ihdr_endy;        /* End Location Y, Anterior max*/
    MY_DG_FLOAT ihdr_strtz;        /* Start Location Z, Superior min*/
    MY_DG_FLOAT ihdr_endz;        /* End Location Z, Superior max*/
    short ihdr_oblique[9];        /* Reserved for future use.*/
    MY_DG_FLOAT ihdr_locatn;        /* Image Location*/
    MY_DG_FLOAT ihdr_tblpos;        /* Table Position*/
    MY_DG_FLOAT ihdr_thick;        /* Thickness*/
    MY_DG_FLOAT ihdr_space;        /* Spacing*/
    short ihdr_round;        /* Round*/
    MY_DG_FLOAT ihdr_tr;            /* Repititon/Recovery Time*/
    MY_DG_FLOAT ihdr_ts;            /* Scan Time*/
    MY_DG_FLOAT ihdr_te;            /* Echo Delay*/
    MY_DG_FLOAT ihdr_ti;            /* Inversion Time*/
    MY_DG_FLOAT ihdr_ty[4];        /* Reserved for future use.*/
    short ihdr_necho;        /* Number of echos.*/
    short ihdr_echon;        /* Echo number.*/
    short ihdr_slquant;        /* Number of slices in scan group.*/
    short ihdr_nave;        /* Number of averages.*/
    short ihdr_rsrch;        /* Research mode used ?*/
    char ihdr_pname[32];        /* Name of PSD file.*/
    short ihdr_psddt[6];        /* Creation Date of PSD file.*/
    short ihdr_gpre;        /* Graphically Prescribed ?*/
    char ihdr_pseries[9];        /* Prescribed Series Numbers*/
    char ihdr_skip5;
    char ihdr_pimages[9];        /* Prescribed Image Numbers*/
    char ihdr_skip6;
    short ihdr_shape;        /* Image Shape*/
    short ihdr_x;            /* X pixel dimension*/
    short ihdr_y;            /* Y pixel dimension*/
    MY_DG_FLOAT ihdr_pixsiz;        /* Pixel Size*/
    short ihdr_cmprs;        /* Image Compressed ?*/
    short ihdr_bitpix;        /* Bits per Pixel*/
    short ihdr_window;        /* Default Window*/
    short ihdr_level;        /* Default Level*/
    short ihdr_ifblks;        /* Number of Blocks in File*/
    MY_DG_FLOAT ihdr_nex;            /* Number of excitations (Real .*/
    MY_DG_FLOAT ihdr_psar;        /* Value of peak SAR (Real .*/
    MY_DG_FLOAT ihdr_asar;        /* Value of average SAR (Real .*/
    short ihdr_monitor;        /* SAR monitored ?*/
    short ihdr_contig;        /* Contiguous slices ?*/
    short ihdr_hrt_rt;        /* Cardiac Heart Rate*/
    MY_DG_FLOAT ihdr_del_trg;        /* Total Delay Time After Trigger*/
    short ihdr_arr;            /* Arrhythmia Rejection Ratio*/
    short ihdr_rtime;        /* Cardiac Rep Time*/
    short ihdr_imgs_pcy;        /* Images per Cardiac Cycle*/
    MY_DG_FLOAT ihdr_arrs_scn;        /* Number of ARR's during the Scan*/
    short ihdr_xmtattn;        /* Transmit attenuator setting*/
    short ihdr_rcvattn;        /* Receive attenuator setting*/
    short ihdr_fldstr;        /* Magnetic Field Strength*/
    short ihdr_rsrv1[91];        /* GE NMR Reserved*/
    short ihdr_rsrv2[255];        /* GE NMR Reserved*/
    short ihdr_check;        /* Image Header Checksum*/
} IMAGE;
