/*********************************************************************
 *
 * IDBM ERROR RETURN DEFINITIONS FOR RELEASE 1.8
 *
 * W.M. Leue  11-20-85
 *
 *********************************************************************/

#define EM_IDBM_RNGPR           2167808         /* ?RNGPR Sys Call Failed */
#define EM_IDBM_RNGLD           2167809         /* ?RNGLD Sys Call Failed */
#define EM_IDBM_RNGAL           2167810         /* IDBM Ring Already Loaded */
#define EM_IDBM_ILFNC           2167811         /* Illegal IDBM Func Code */
#define EM_IDBM_ILSFNC          2167812         /* Illegal IDBM SubFunc Code */
#define EM_IDBM_ILLVL           2167813         /* Illegal IDBM Level Code */
#define EM_IDBM_OFILE           2167814         /* Open File Error */
#define EM_IDBM_RFILE           2167815         /* Read File Error */
#define EM_IDBM_WFILE           2167816         /* Write File Error */
#define EM_IDBM_CRFILE          2167817         /* Create File Error */
#define EM_IDBM_CFILE           2167818         /* Close File Error */
#define EM_IDBM_DFILE           2167819         /* Delete File Error */
#define EM_IDBM_UINP            2167820         /* No User Init Done */
#define EM_IDBM_UIP             2167821         /* User Init Already Done */
#define EM_IDBM_MSTU            2167822         /* Too Many Studies */
#define EM_IDBM_SPACE           2167823         /* Can't Size Disk */
#define EM_IDBM_MINSP           2167824         /* Out of Disk Space */
#define EM_IDBM_SOPEN           2167825         /* ?SOPEN Sys Call Failed */
#define EM_IDBM_SPAGE           2167826         /* ?SPAGE Sys Call Failed */
#define EM_IDBM_SCLOSE          2167827         /* ?SCLOSE Sys Call Failed */
#define EM_IDBM_MAXSTU          2167828         /* Max Study Number Exceeded */
#define EM_IDBM_MAXSER          2167829         /* Max 31 Series in Study */
#define EM_IDBM_MAXIMA          2167830         /* Max 512 Images in Series */
#define EM_IDBM_LCLOCK          2167831         /* Lock Local Data Failed */
#define EM_IDBM_LCUNLOCK        2167832         /* Unlock Local Data Failed */
#define EM_IDBM_PSTAT           2167833         /* Process Stats Fetch Fail */
#define EM_IDBM_TBD             2167834         /* Funcion Not Yet Available */
#define EM_IDBM_ILPID           2167835         /* Illegal Patient ID */
#define EM_IDBM_ILSTU           2167836         /* Illegal Study Number */
#define EM_IDBM_ILRRR           2167837         /* Illegal Raw System ID */
#define EM_IDBM_ILSER           2167838         /* Illegal Series Number */
#define EM_IDBM_ILIII           2167839         /* Illegal System ID */
#define EM_IDBM_ILIMAGE         2167840         /* Illegal Image Number */
#define EM_IDBM_ALLOC           2167841         /* Can't Alloc DSS Page */
#define EM_IDBM_DECZERO         2167842         /* Archive Pend Cnt < 0 */
#define EM_IDBM_FALLLE          2167843         /* Alloc Shared lock Fail */
#define EM_IDBM_DEALLLE         2167844         /* Dealloc Shared Lock Fail */
#define EM_IDBM_LOCK            2167845         /* Lock Shared Data Fail */
#define EM_IDBM_UNLOCK          2167846         /* Unlock Shared Data Fail */
#define EM_IDBM_SDIRFULL        2167847         /* Max 31 Series in DSS */
#define EM_IDBM_CHECK           2167848         /* Bad Hdr Checksum */
#define EM_IDBM_SERARCH         2167849         /* Series has been Archived */
#define EM_IDBM_DBERRF          2167850         /* IDBM Fatal Internal Err */
#define EM_IDBM_ARCURSCN        2167851         /* Cannot Archive Curr Stdy */

#define EM_IDBM_STATMIN         2168320         /* Minimum Code Number */
#define EM_IDBM_NPID            2168321         /* No Such Patient */
#define EM_IDBM_NSTU            2168322         /* No Such Study */
#define EM_IDBM_NSER            2168323         /* No Such Series */
#define EM_IDBM_NIMAGE          2168324         /* No Such Image */
#define EM_IDBM_EOL             2168325         /* End of List */
#define EM_IDBM_FEXACC          2168326         /* File Exclusive Access */
#define EM_IDBM_FACC            2168327         /* No Exclusive Access */
#define EM_IDBM_ARCH            2168328         /* Structure is Archived */
#define EM_IDBM_NOARCH          2168329         /* Structure not Archived */
#define EM_IDBM_AARCH           2168330         /* Structure is Archived */
#define EM_IDBM_INSSP           2168331         /* Insufficient Disk Space */
#define EM_IDBM_FLINUSE         2168332         /* Structure in Use */
#define EM_IDBM_DBERR           2168333         /* Internal Data Base Err */
#define EM_IDBM_PIDAEX          2168334         /* Patient Already Exists */
#define EM_IDBM_STUAEX          2168335         /* Study Already Exists */
#define EM_IDBM_SERAEX          2168336         /* Series Already Exists */
#define EM_IDBM_IMAAEX          2168337         /* Image Already Exists */
#define EM_IDBM_CURSCNST        2168338         /* Study in Use */
#define EM_IDBM_STATMAX         2168339         /* Maximum Code Number */
#define EM_IDBM_NHPID           2168340         /* No Such Hospital Patient */
#define EM_IDBM_NMOD            2168341         /* No Such Modality */
#define EM_IDBM_NSYS            2168342         /* No Such System */

/*
SUN IDBM errors
*/

#define SUN_IDBM_CONFIG         2000000         /* Cannot read config file */
#define SUN_IDBM_IDENT          2000001         /* ICBM ident failure */
#define SUN_IDBM_CONCT          2000002         /* Cannot connect to database server */
#define SUN_ICBM_WTERR          2000003         /* Error writing to server*/
#define SUN_ICBM_RDERR          2000004         /* Error reading from server */
#define SUN_IDBM_UNKNWN         2000005         /* data base does not exist */
#define SUN_ICBM_DCONCT         2000006         /* IDCBM disconnect */
#define SUN_IDBM_LOCKED         2000007         /* Database open by other host */
#define SUN_IDBM_NOMOUNT        2000008         /* Database not mounted on your
                       host. Only list functions available. */
#define SUN_IDBM_BIGHDR        2000009         /* Image header too large */
#define SUN_IDBM_NOLOCK        2000010         /* Cannot lock database */

/* end include file */
