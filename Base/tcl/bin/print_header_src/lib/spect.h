
#define HEADER_VALID 0
#define HEADER_INVALID -1

/* data_format */
#define CHAR_PIXEL 0
#define INT_PIXEL 1
#define LONG_PIXEL 2
#define FLOAT_PIXEL 3

/* standard output pixel type */
#define DEFAULT_PIXEL_FORMAT (INT_PIXEL)

/* file_type */
#define CIRCULAR_PROJECTION 1
#define FLAT_PROJECTION 2
#define RECONSTRUCTED 4
#define PROCESSED 8

/* collimator_type */
#define COLLIMATOR_TRIAD 0
#define COLLIMATOR_CALIBRATION 1

/* acquisition_type */
#define STEP_SHOOT 0
#define CONTINUOUS_ROTATION 1

#define MAX_COLLIMATOR_SEGMENTS 8

/* stored left/right reversed ?? */
#define LEFT_RIGHT_NOT_REVERSED 0
#define LEFT_RIGHT_REVERSED 1

typedef struct
{
    short int dimx;
    short int dimy;
    short int dimz;
    short int bytes_per_pixel;
    short int data_format;
    short int file_type;
    float total_counts;
    float min_count;
    float max_count;
    short int collimator_type;
    short int collimator_number;
    float start_z;
    float end_z;
    short int acquisition_type;
    float start_angle;
    float end_angle;
    float seconds_per_view;
    long counts_per_view;
    short int number_views;
    char isotope[8];
    float isotope_halflife;
    char dose[8];
    float energy_lld;
    float energy_uld;
    float scaling_slope; /* pixval / scaling_slope give good grayscale val */
    float scaling_offset;
    char datetime[20];
    char patient_name[30];
    char patient_birthdate[10];
    char patient_number[14];
    char physician[30];
    char description[60];
    short int collimator_segment_number;
    float segment_centers[MAX_COLLIMATOR_SEGMENTS];
    float segment_size[MAX_COLLIMATOR_SEGMENTS];
    char version[15];
    char left_right_reversed;

} SPECT_HEADER;

