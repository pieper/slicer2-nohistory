/*@DESCRIPTION
 *
 *
 *  modified to change strusture to char offsets.
 *  this structure is good for both SUN3 and SUN4 but structures are not
 *  ment to be used to layout fixed memory layouts
 *
 *
 * DESCRIPTION OF HEADER FOR FILES CONTAINING DEEP PIXEL MEDICAL IMAGES
 *
 *    THE STRUCTURES OF THIS FILE ARE DESIGNED WITH 32 BIT WORD
 *   WORD ALIGNMENT IN MIND.  THIS IS DONE TO FACILITATE THE EASY
 *   ACCESS TO THE DATA WITHIN A 'SPARC' BASED PROCESSOR AS IS FOUND
 *   IN THE GENESIS IP AND FRAME BUFFER.  ADDITIONS AND CHANGES SHOULD
 *   REFLECT THIS DESIGN REQUIREMENT ON THE STRUCTURES OF THIS FILE.
 *
 *      AN PIXELDATA FILE CONTAINS ONLY THE INFORMATION NEEDED TO HANDLE THE
 *   PHYSICAL PIXELS OF AN IMAGE WITHOUT CONCERN FOR WORLDLY RELATIONSHIPS
 *   TO WHAT THEY REPRESENT.  THERE IS A HEADER, A COUPLE OF OPTIONAL 
 *   CONTROL TABLES, AND VALUES OF DATA THAT ARE REPRESENTATIONS OF THE
 *   REAL PIXEL VALUES OF THE IMAGE TO BE SET INTO DISPLAY HARDWARE.  THE
 *   DATA BASE HEADER STUFF IS A BLOCK OF DATA THAT PIXELDATA DOES NOT
 *   INTERPET, BUT KEEPS FOR THE DATA BASE.  (THIS SHOULD ONLY BE FILLED
 *   IN ON THE OPTICAL DISK).
 *
 *      THESE DATA VALUES MIGHT NEED TO BE MANIPULATED TO GET THE REAL
 *   PIXEL VALUES VIA UNCOMPRESSION AND/OR UNPACKING DEPENDING ON THE
 *   VALUE OF 'IMG_COMPRESS'.  IF THE FILE HAS BOTH METHODS APPLIED
 *   (IMG_COMPRESS == IC_COMPACK), THE UNCOMPRESSION MUST BE PERFORMED
 *   BEFORE UNPACKING.
 *
 *      THE HEADER CONTAINS 'BYTE DISPLACEMENT' AND 'BYTE LENGTH' ENTRIES
 *   TO ACCESS THE DIFFERENT CONTROL TABLES OR DATA.  A CONTROL
 *   TABLE DOES NOT EXIST IF ITS 'BYTE LENGTH' IS ZERO.  IF THE
 *   TABLE EXISTS, THERE IS A STRUCTURE THAT DEFINES THE SECONDARY TABLE.
 *   THERE IS ALSO AN UNFILLED AREA BETWEEN THE LAST CONTROL TABLE AND
 *   START OF DATA.  THIS AREA IS THERE TO BLOCK ALIGN THE BEGINNING OF
 *   THE DATA.  THIS WILL ALLOW FOR MUCH BETTER READ AND WRITE PERFORMANCE
 *   WHEN GOING TO BLOCK ORIENTED DEVICES (THE NORM FOR OUR APPLICATION).
 *   THE SIZE OF THIS AREA WILL VARY DEPENDING ON WHICH CONTROL TABLES
 *   ARE DEFINED AND THEIR SIZES AND THE SECTOR SIZE OF THE STORAGE
 *   DEVICE.  IT IS IMPORTANT TO NOTE THAT THIS GAP SIZE CAN CHANGE
 *   WHEN MOVING FROM ONE PHYSICAL DEVICE TO ANOTHER IF THEY HAVE DIFFERENT
 *   SECTOR SIZES.
 *
 *    ONE CAN FIND A DESCRIPTION OF THE STRUCTURE OF EACH OF THE OPTIONAL
 *   PARTS IN THE HEADER FILE ASSOCIATED WITH THAT OPTIONAL AREA.
 *
 *   IF THE FILE IS FOUND TO BE IC_COMPRESSED OR IC_COMPACK, THE METHOD IS...
 *      THE COMPRESSION ALGORITHM STORES IN THE FILE A DIFFERENTIAL
 *   INTENSITY VALUE FROM THE IMMEDIATELY PRECEEDING PIXEL.  THE VALUE
 *   STORED AS A 7 BIT 2'S COMPLIMENT NUMBER (8TH MSBIT ZERO) BYTE IF THE
 *   DIFFERENCE IS -64 TO +63.  IF THE DIFFERENCE IS -8192 TO +8191, THE
 *   FIRST BYTE STORED IS THE MOST SIGNIFICANT BYTE OF THE 2'S COMPLIMENT
 *   VALUE WITH THE TOP TWO BITS SET TO '10'.  IF THE DIFFERENCE EXCEEDS
 *   13 BIT MAGNITUDE, THE FIRST BYTE STORED IS '11XXXXXX' WITH THE NEXT
 *   TWO BYTES CONTAINING THE ACTUAL REAL PIXEL VALUE.
 *
 *   IF THE FILE IS FOUND TO BE IC_COMP2 OR IC_CPK2, THE METHOD IS ...
 *      THE COMPRESSION ALGORITHM STORES IN THE FILE A DIFFERENTIAL
 *   INTENSITY VALUE FROM THE IMMEDIATELY PRECEEDING PIXEL.  THE VALUE
 *   OF THE FIRST BYTE BEING 128 (-128) INDICATES THAT THE NEXT TWO BYTES
 *   ARE THE ACTUAL REAL PIXEL VALUE.  OTHERWISE, THE VALUE OF THE FIRST
 *   BYTE WILL BE AN 8 BIT 2'S COMPLIMENT NUMBER BETWEEN -127 TO +127 TO
 *   BE ADDED THE VALUE OF THE PREVIOUS PIXEL.  THESE ARE NOT CURRENTLY
 *   SUPPORTED IN GENESIS.
 *
 *      THE CHECKSUM METHOD OF THE FILE AS OF THIS DATE (19-JAN-88) IS:
 *   THE NUMBER STORED IN 'IMG_CHECKSUM' IS THE 16 BIT (U_SHORT) SUM
 *   OF ALL THE PIXEL DATA OF THE IMAGE ADDING IN THE OVERFLOWS DURING
 *   THE SUMMATION.  THIS IS REFERED TO AS 'END-AROUND-CARRY' SUMMATION 
 *   SO THAT THE VALUE OF ZERO REALLY (ABSOLUTELY) MEANS THAT THERE IS 
 *   NO CHECKSUM COMPUTED FOR THIS IMAGE.  NOTE THAT THE CHECKSUM IS 
 *   COMPUTED ON THE REAL ORIGINAL PIXEL DATA VALUES OF THE IMAGE AND
 *   NOT ON THE 'COMPRESSED' OR 'COMPACK'D DATA VALUES IN THE FILE.
 *   THIS IMPLIES THAT THE CHECKSUM OF A RECTANGULAR VERSION OF A PACKED
 *   FILE MAY WELL BE DIFFERENT FROM THE PACKED VERSION; SINCE THE 
 *   BACKGROUND VALUES GET ADDED IN FOR THE RECTANGULAR VERSION AND NOT
 *   FOR THE PACKED VERSION.
 *
 * NOTES ON THE IMAGE HEADER:
 *  IMG_MAGIC =       A LONG INTEGER VALUE TO INDICATE AN 'IMAGEFILE'
 *  IMG_HDR_LENGTH =  LENGTH OF ALL HEADERS IN BYTES - POINTS TO PIXELS START
 *              AS A BYTE DISPLACEMENT TO THE 'PIXEL DATA AREA'
 *  IMG_WIDTH =       X-AXIS PIXEL COUNT (256, 320, 512, 1024)
 *  IMG_HEIGHT =      Y-AXIS PIXEL COUNT
 *  IMG_DEPTH =       NUMBER OF BITS IN AN UNCOMPRESSED PIXEL (1, 8, 16)
 *            NOTE: NOT MAGNITUDE RESOLUTION (CT IS 16, NOT 12)
 *  IMG_COMPRESS =    FORM OF COMPRESSION AND PACKING APPLIED TO FILE (IC_*)
 *  IMG_DWINDOW =     DEFAULT 'WINDOW' WIDTH (STORED IMAGE VALUE RANGE)
 *  IMG_DLEVEL =      DEFAULT 'LEVEL' VALUE  (STORED IMAGE VALUE MAGNITUDE)
 *  IMG_BGSHADE =     DEFAULT BACKGROUND SHADE FOR NON-PIXELS DURING UNPACK
 *  IMG_OVRFLOW =     PIXEL VALUE TO SUBSTITUTE WHEN OVERFLOW OCCURS IN GIP
 *  IMG_UNDFLOW =     PIXEL VALUE TO SUBSTITUE WHEN UNDERFLOW OCCURS IN GIP
 *  IMG_TOP_OFFSET =  NUMBER OF LINES WITHOUT ENTRIES IN 'LINE_LENGTH' TABLE
 *                      AT THE TOP OF THE IMAGE.
 *  IMG_BOT_OFFSET =  NUMBER OF LINES WITHOUT ENTRIES IN 'LINE_LENGTH' TABLE
 *                      AT THE BOTTOM OF THE IMAGE.
 *  IMG_VERSION =     THE VERSION OF THE HEADER STRUCTURE - INITIAL = 0
 *            THIS WORD IS NOT PROCESSED BY THE IPLIB!  THEREFORE
 *            ALL CHANGES TO THIS HEADER MUST BE HANDLED BY
 *            EXTENSION AND NOT BY ALTERATION OF THE 3.1 VERSION
 *            OF THE PIXHDR STRUCTURE CALLED VERSION 0!
 *  IMG_CHECKSUM =    THE 16 BIT END-AROUND-CARRY SUM OF TRUE IMAGE PIXELS
 *            (A VALUE OF ZERO INDICATES THAT THE CHECKSUM IS NOT
 *              DEFINED FOR THIS FILE.)
 *  IMG_P_ID;          A BYTE DISPLACEMENT TO UNIQUE IMAGE IDENTIFIER
 *  IMG_L_ID;          A BYTE LENGTH OF UNIQUE IMAGE IDENTIFIER
 *  IMG_P_UNPACK =    A BYTE DISPLACEMENT TO THE 'UNPACK CONTROL TABLE'
 *  IMG_L_UNPACK =    BYTE LENGTH OF THE 'UNPACK CONTROL TABLE'
 *  IMG_P_COMPRESS =  A BYTE DISPLACEMENT TO THE 'COMPRESSION CONTROL TABLE'
 *  IMG_L_COMPRESS =  BYTE LENGTH OF THE 'COMPRESSION CONTROL TABLE'
 *  IMG_P_HISTO =     A BYTE DISPLACEMENT TO THE 'HISTOGRAM CONTROL DATA'
 *  IMG_L_HISTO =     BYTE LENGTH OF THE 'HISTOGRAM CONTROL DATA'
 *  IMG_P_TEXT =      A BYTE DISPLACEMENT TO 'TEXT PLANE DATA'
 *  IMG_L_TEXT =      BYTE LENGTH OF 'TEXT PLANE DATA'
 *  IMG_P_GRAPHICS =  A BYTE DISPLACEMENT TO 'GRAPHICS PLANE DATA'
 *  IMG_L_GRAPHICS =  BYTE LENGTH OF 'GRAPHICS PLANE DATA'
 *  IMG_P_DBHDR =     A BYTE DISPLACEMENT TO 'DATA BASE HEADER DATA'
 *  IMG_L_DBHDR =     BYTE LENGTH OF 'DATA BASE HEADER DATA'
 *  IMG_LEVELOFFSET=  OFFSET TO BE ADDED TO PIXEL VALUES TO GET CORRECT
 *            PRESENTATION VALUE
 *  IMG_P_USER=       BYTE DISPLACEMENT TO USER DEFINED DATA 
 *  IMG_L_USER=          BYTE LENGTH OF USER DEFINED DATA             
 *
 *
 *    HERE IS A PICTURE TO HELP VISUALIZE THE STRUCTURE OF THE HEADER.
 *
 *                ---------------------------------
 *                |  MAGIC NUMBER                 |
 *                ---------------------------------
 *                  --|  HEADER LENGTH        |
 *                 |  ---------------------------------
 *                 |  |  LOTS OF HEADER STUFF        |
 *                 |  ~                ~
 *                 |  ~                ~
 *                 |  ---------------------------------
 *                 |  |  VERSION    |  CHECKSUM    |
 *                 |  ---------------------------------
 *                -|--|  ID POINTER            |
 *               | |  ---------------------------------
 *               | |  |  ID LENGTH            |
 *               | |  ---------------------------------
 *              -|-|--|  UNPACK TABLE POINTER        |
 *             | | |  ---------------------------------
 *             | | |  |  UNPACK TABLE LENGTH        |
 *             | | |  ---------------------------------
 *            -|-|-|--|  COMPRESSION SEED TABLE PTR    |
 *             | | | |  ---------------------------------
 *             | | | |  |  COMPRESSION SEED TABLE LENGTH|
 *             | | | |  ---------------------------------
 *            -|-|-|-|--|  HISTOGRAM TABLE POINTER    |
 *           | | | | |  ---------------------------------
 *           | | | | |  |  HISTOGRAM TABLE LENGTH    |
 *           | | | | |  ---------------------------------
 *          -|-|-|-|-| --  TEXT PLANE DATA POINTER    |
 *         | | | | | |  ---------------------------------
 *         | | | | | |  |  TEXT PLANE DATA LENGTH    |
 *         | | | | | |  ---------------------------------
 *        -|-|-|-|-|-| --  GRAPHICS PLANE DATA POINTER    |
 *       | | | | | | |  ---------------------------------
 *       | | | | | | |  |  GRAPHICS PLANE DATA LENGTH    |
 *       | | | | | | |  ---------------------------------
 *      -|-|-|-|-|-|-| --  DATA BASE HEADER POINTER    |
 *     | | | | | | | |  ---------------------------------
 *     | | | | | | | |  |  DATA BASE HEADER LENGTH    |
 *     | | | | | | | |  ---------------------------------
 *     | | | | | | | |  |  LEVEL OFFSET            |
 *     | | | | | | | |  ---------------------------------
 *    -|-|-|-|-|-|-|-| --  USER DEFINED DATA POINTER    |
 *   | | | | | | | | |  ---------------------------------
 *   | | | | | | | | |  |  USER DEFINED DATA LENGTH     |
 *   | | | | | | | | |  --------------------------------- 
 *   | | | | | | | | |  |  SOME SPARES            |
 *   | | | | | | | | |  ~                ~
 *   | | | | | | | | |  ~                ~
 *   | | | | | | | | |  ---------------------------------\
 *   | | | | | | | |-|->~  ID STUFF            ~ \
 *   | | | | | | |   |  ~  SEE PDTEXT.H FOR DETAILS    ~ /  ID LENGTH
 *   | | | | | | |   |  ---------------------------------/\
 *   | | | | | | |---|->~  UNPACK TABLE            ~  \  UNPACK TABLE
 *   | | | | | |     |  ~  DESCRIBED BELOW        ~  /   LENGTH
 *   | | | | | |     |  ---------------------------------\/
 *   | | | | | |-----|->~  COMPRESSION SEED TABLE    ~ \  COMPRESSION SEED
 *   | | | | |       |  ~  SEE PDCOMP.H FOR DETAILS    ~ /   TABLE LEN
 *   | | | | |       |  ---------------------------------/\
 *   | | | | |-------|->~  HISTOGRAM TABLE        ~  \  HISTOGRAM TABLE
 *   | | | |          |  ~  SEE PDHISTO.H FOR DETAILS    ~  /   LENGTH
 *   | | | |         |  ---------------------------------\/
 *   | | | |---------|->~  TEXT PLANE DATA        ~ \  TEXT PLANE DATA
 *   | | |           |  ~  SEE PD?????.H FOR DETAILS    ~ /   LENGTH
 *   | | |           |  ---------------------------------/\
 *   | | |-----------|->~  GRAPHICS PLANE DATA        ~  \  GRAPHICS PLANE
 *   | |              |  ~  SEE PD?????.H FOR DETAILS    ~  /   DATA LENGTH
 *   | |             |  ---------------------------------\/
 *   | |-------------|->~  DATA BASE HEADER        ~ \  DATA BASE HEADER
 *   |               |  ~  SEE PD?????.H FOR DETAILS    ~ /   LENGTH
 *   |               |  ---------------------------------/\  
 *   |---------------|->~  USER DEFINED DATA        ~  \ USER DEFINED DATA 
 *                 |  ~  SEE PD????.H FOR DETAILS    ~  /  LENGTH
 *                   |  --------------------------------- /
 *                 |  ~    BLOCK ALIGNMENT GAP    ~
 *                 |  ~                ~
 *                 |  ---------------------------------
 *                 |->~    PIXEL DATA        ~
 *                ~                ~
 *                ---------------------------------
 *
 *    IF ANY OF THE TABLES IS OF ZERO LENGTH, THE POINTER TO THAT TABLE
 *   AND THE POINTER TO THE NEXT TABLE WOULD BOTH POINT TO THE SAME PLACE.
 *   THE ORDER ABOVE IS WHAT ONE WILL TYPICALLY FIND, BUT ONE MUST FOLLOW
 *   THE POINTERS AND USE THE LENGTHS TO FIND THE TABLES.  THERE IS NO
 *   REQUIREMENT THAT THEY BE IN THIS ORDER.
 */

/*@END*********************************************************/

#define IMG_MAGIC 0        /* MAGIC NUMBER */
#define IMG_HDR_LENGTH 4    /* LENGTH OF TOTAL HEADER IN BYTES AND A BYT */ 
                /* DISPLACEMENT TO THE 'PIXEL DATA AREA' */
#define IMG_WIDTH 8        /* WIDTH (PIXELS) OF IMAGE */
#define IMG_HEIGHT 12        /* HEIGHT (PIXELS) OF IMAGE */
#define IMG_DEPTH 16        /* DEPTH (1, 8, 16, OR 24 BITS) OF PIXEL */
#define IMG_COMPRESS 20        /* TYPE OF COMPRESSION; SEE IC_* BELOW */
#define IMG_DWINDOW 24        /* DEFAULT WINDOW SETTING */
#define IMG_DLEVEL 28        /* DEFAULT LEVEL SETTING */
#define IMG_BGSHADE 32        /* BACKGROUND SHADE TO USE FOR NON-IMAGE */
#define IMG_OVRFLOW 36        /* OVERFLOW VALUE */
#define IMG_UNDFLOW 40        /* UNDERFLOW VALUE */
#define IMG_TOP_OFFSET 44    /* NUMBER OF BLANK LINES AT IMAGE TOP */
#define IMG_BOT_OFFSET 48    /* NUMBER OF BLANK LINES AT IMAGE BOTTOM */
#define IMG_VERSION 52        /* VERSION OF THE HEADER STRUCTURE  */
                /* AND A WORD TO MAINTAIN 32 BIT ALIGNMENT */
#define IMG_CHECKSUM 54        /* 16 BIT END_AROUND_CARRY SUM OF PIXELS */
#define IMG_P_ID 56        /* A BYTE DISP TO UNIQUE IMAGE IDENTIFIER */
#define IMG_L_ID 60        /* BYTE LENGTH OF UNIQUE IMAGE IDENTIFIER */
#define IMG_P_UNPACK 64        /* A BYTE DISP TO 'UNPACK CONTROL' */
#define IMG_L_UNPACK 68        /* BYTE LENGTH OF 'UNPACK CONTROL' */
#define IMG_P_COMPRESS 72    /* A BYTE DISP TO 'COMPRESSION CONTROL' */
#define IMG_L_COMPRESS 76    /* BYTE LENGTH OF 'COMPRESSION CONTROL' */
#define IMG_P_HISTO 80        /* A BYTE DISP TO 'HISTOGRAM CONTROL' */
#define IMG_L_HISTO 84        /* BYTE LENGTH OF 'HISTOGRAM CONTROL' */
#define IMG_P_TEXT 88        /* A BYTE DISP TO 'TEXT PLANE DATA' */
#define IMG_L_TEXT 92        /* BYTE LENGTH OF 'TEXT PLANE DATA' */
#define IMG_P_GRAPHICS 96    /* A BYTE DISP TO 'GRAPHICS PLANE DATA' */
#define IMG_L_GRAPHICS 100    /* BYTE LENGTH OF 'GRAPHICS PLANE DATA' */
#define IMG_P_DBHDR 104        /* A BYTE DISP TO 'DATA BASE HEADER DATA' */
#define IMG_L_DBHDR 108        /* BYTE LENGTH OF 'DATA BASE HEADER DATA' */
#define IMG_LEVELOFFSET 112    /* VALUE TO ADD TO STORED PIXEL DATA VALUES */
                /* TO GET THE CORRECT PRESENTATION VALUE */
#define IMG_P_USER 116        /* BYTE DISPLACEMENT TO USER DEFINED DATA */
#define IMG_L_USER 120        /* BYTE LENGTH OF USER DEFINED DATA */
#define    IMG_P_SUITE 124        /* BYTE DISPLACEMENT TO SUITE HEADER DATA */
#define    IMG_L_SUITE 128        /* BYTE LENGTH OF SUITE DATA */        
#define    IMG_P_EXAM 132        /* BYTE DISPLACEMENT TO EXAM DATA */    
#define    IMG_L_EXAM 136        /* BYTE LENGTH OF EXAM DATA */
#define    IMG_P_SERIES 140    /* BYTE DISPLACEMENT TO SERIES DATA */        
#define    IMG_L_SERIES 144    /* BYTE LENGTH OF SERIES DATA */        
#define    IMG_P_IMAGE 148        /* BYTE DISPLACEMENT TO IMAGE DATA */        
#define    IMG_L_IMAGE 152        /* BYTE LENGTH OF IMAGE DATA */            
#define PIX_HDR_LEN 156

