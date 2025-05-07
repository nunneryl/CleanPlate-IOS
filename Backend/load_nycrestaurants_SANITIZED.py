{\rtf1\ansi\ansicpg1252\cocoartf2821
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Bold;\f1\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red252\green95\blue163;\red31\green31\blue36;\red255\green255\blue255;
\red108\green121\blue134;\red252\green106\blue93;\red208\green191\blue105;}
{\*\expandedcolortbl;;\csgenericrgb\c98839\c37355\c63833;\csgenericrgb\c12054\c12284\c14131;\csgenericrgb\c100000\c100000\c100000\c85000;
\csgenericrgb\c42394\c47462\c52518;\csgenericrgb\c98912\c41558\c36568;\csgenericrgb\c81498\c74939\c41233;}
\margl1440\margr1440\vieww22620\viewh14100\viewkind0
\deftab593
\pard\tx593\pardeftab593\partightenfactor0

\f0\b\fs24 \cf2 \cb3 import
\f1\b0 \cf4  os\

\f0\b \cf2 import
\f1\b0 \cf4  psycopg2\

\f0\b \cf2 import
\f1\b0 \cf4  requests\

\f0\b \cf2 import
\f1\b0 \cf4  logging\

\f0\b \cf2 from
\f1\b0 \cf4  dateutil.parser 
\f0\b \cf2 import
\f1\b0 \cf4  parse 
\f0\b \cf2 as
\f1\b0 \cf4  date_parse\
\
\cf5 # Setup logging\cf4 \
logging.basicConfig(level=logging.INFO)\
logger = logging.getLogger(__name__)\
\
DB_NAME = os.environ.get(\cf6 "DB_NAME"\cf4 , \cf6 \'93Use_Real\cf4 )\
DB_USER = os.environ.get(\cf6 "DB_USER"\cf4 , \cf6 \'93Use\'94_Real\cf4 )\
DB_PASSWORD = os.environ.get(\cf6 "DB_PASSWORD"\cf4 , \cf6 \'93Use_Real\cf4 )\
DB_HOST = os.environ.get(\cf6 "DB_HOST"\cf4 , \cf6 \'93Use\'94_Real\cf4 )\
\

\f0\b \cf2 try
\f1\b0 \cf4 :\
    conn = psycopg2.connect(\
        dbname=DB_NAME,\
        user=DB_USER,\
        password=DB_PASSWORD,\
        host=DB_HOST\
    )\
    logger.info(\cf6 "Connected to database"\cf4 )\

\f0\b \cf2 except
\f1\b0 \cf4  Exception 
\f0\b \cf2 as
\f1\b0 \cf4  e:\
    logger.error(\cf6 "Database connection failed: %s"\cf4 , e)\
    
\f0\b \cf2 raise
\f1\b0 \cf4  e\
\

\f0\b \cf2 def
\f1\b0 \cf4  convert_date(date_str):\
    
\f0\b \cf2 if
\f1\b0 \cf4  
\f0\b \cf2 not
\f1\b0 \cf4  date_str 
\f0\b \cf2 or
\f1\b0 \cf4  date_str == \cf6 "N/A"\cf4 :\
        
\f0\b \cf2 return
\f1\b0 \cf4  
\f0\b \cf2 None
\f1\b0 \cf4 \
    
\f0\b \cf2 try
\f1\b0 \cf4 :\
        dt = date_parse(date_str)\
        
\f0\b \cf2 return
\f1\b0 \cf4  dt.date()\
    
\f0\b \cf2 except
\f1\b0 \cf4  Exception 
\f0\b \cf2 as
\f1\b0 \cf4  e:\
        logger.error(\cf6 "Error parsing date %s: %s"\cf4 , date_str, e)\
        
\f0\b \cf2 return
\f1\b0 \cf4  
\f0\b \cf2 None
\f1\b0 \cf4 \
\

\f0\b \cf2 def
\f1\b0 \cf4  convert_float(value):\
    
\f0\b \cf2 if
\f1\b0 \cf4  
\f0\b \cf2 not
\f1\b0 \cf4  value 
\f0\b \cf2 or
\f1\b0 \cf4  value == \cf6 "N/A"\cf4 :\
        
\f0\b \cf2 return
\f1\b0 \cf4  
\f0\b \cf2 None
\f1\b0 \cf4 \
    
\f0\b \cf2 try
\f1\b0 \cf4 :\
        
\f0\b \cf2 return
\f1\b0 \cf4  float(value)\
    
\f0\b \cf2 except
\f1\b0 \cf4  ValueError 
\f0\b \cf2 as
\f1\b0 \cf4  e:\
        logger.error(\cf6 "Error converting value to float: %s"\cf4 , e)\
        
\f0\b \cf2 return
\f1\b0 \cf4  
\f0\b \cf2 None
\f1\b0 \cf4 \
\
limit = \cf7 50000\cf4 \
offset = \cf7 0\cf4 \
total_rows_fetched = \cf7 0\cf4 \
\

\f0\b \cf2 while
\f1\b0 \cf4  
\f0\b \cf2 True
\f1\b0 \cf4 :\
    url = f\cf6 "https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit=\{limit\}&$offset=\{offset\}"\cf4 \
    
\f0\b \cf2 try
\f1\b0 \cf4 :\
        response = requests.get(url)\
    
\f0\b \cf2 except
\f1\b0 \cf4  Exception 
\f0\b \cf2 as
\f1\b0 \cf4  e:\
        logger.error(\cf6 "Error fetching data: %s"\cf4 , e)\
        
\f0\b \cf2 break
\f1\b0 \cf4 \
\
    
\f0\b \cf2 try
\f1\b0 \cf4 :\
        data = response.json()\
    
\f0\b \cf2 except
\f1\b0 \cf4  Exception 
\f0\b \cf2 as
\f1\b0 \cf4  e:\
        logger.error(\cf6 "Error parsing JSON: %s"\cf4 , e)\
        
\f0\b \cf2 break
\f1\b0 \cf4 \
\
    
\f0\b \cf2 if
\f1\b0 \cf4  
\f0\b \cf2 not
\f1\b0 \cf4  data:\
        logger.info(\cf6 "All data fetched. Total rows inserted: %s"\cf4 , total_rows_fetched)\
        
\f0\b \cf2 break
\f1\b0 \cf4 \
\
    
\f0\b \cf2 for
\f1\b0 \cf4  item 
\f0\b \cf2 in
\f1\b0 \cf4  data:\
        
\f0\b \cf2 try
\f1\b0 \cf4 :\
            \cf5 # Truncate and replace missing values with defaults\cf4 \
            camis = item.get(\cf6 "camis"\cf4 , \cf6 "N/A"\cf4 )\
            dba = item.get(\cf6 "dba"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 255\cf4 ]\
            building = item.get(\cf6 "building"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 50\cf4 ]\
            street = item.get(\cf6 "street"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 255\cf4 ]\
            boro = item.get(\cf6 "boro"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 50\cf4 ]\
            zipcode = item.get(\cf6 "zipcode"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 20\cf4 ]\
            phone = item.get(\cf6 "phone"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 20\cf4 ]\
            cuisine_description = item.get(\cf6 "cuisine_description"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 255\cf4 ]\
            grade = item.get(\cf6 "grade"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]\
            grade_date = convert_date(item.get(\cf6 "grade_date"\cf4 , 
\f0\b \cf2 None
\f1\b0 \cf4 ))\
            inspection_date = convert_date(item.get(\cf6 "inspection_date"\cf4 , 
\f0\b \cf2 None
\f1\b0 \cf4 ))\
            violation_code = item.get(\cf6 "violation_code"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 50\cf4 ]\
            violation_description = item.get(\cf6 "violation_description"\cf4 , \cf6 "N/A"\cf4 )\
            inspection_type = item.get(\cf6 "inspection_type"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 255\cf4 ]\
            critical_flag = item.get(\cf6 "critical_flag"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 50\cf4 ]\
            record_date = convert_date(item.get(\cf6 "record_date"\cf4 , 
\f0\b \cf2 None
\f1\b0 \cf4 ))\
            latitude = convert_float(item.get(\cf6 "latitude"\cf4 , 
\f0\b \cf2 None
\f1\b0 \cf4 ))\
            longitude = convert_float(item.get(\cf6 "longitude"\cf4 , 
\f0\b \cf2 None
\f1\b0 \cf4 ))\
            community_board = item.get(\cf6 "community_board"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]\
            council_district = item.get(\cf6 "council_district"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]\
            census_tract = item.get(\cf6 "census_tract"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]\
            bin_val = item.get(\cf6 "bin"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]  \cf5 # Avoid using built-in 'bin'\cf4 \
            bbl = item.get(\cf6 "bbl"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]\
            nta = item.get(\cf6 "nta"\cf4 , \cf6 "N/A"\cf4 )[:\cf7 10\cf4 ]\
\
            
\f0\b \cf2 with
\f1\b0 \cf4  conn.cursor() 
\f0\b \cf2 as
\f1\b0 \cf4  cur:\
                cur.execute(\cf6 """\cf4 \
\cf6                     INSERT INTO restaurants (\cf4 \
\cf6                         camis, dba, boro, building, street, zipcode, phone, inspection_date,\cf4 \
\cf6                         critical_flag, record_date, latitude, longitude, community_board,\cf4 \
\cf6                         council_district, census_tract, bin, bbl, nta, cuisine_description,\cf4 \
\cf6                         grade, grade_date, inspection_type\cf4 \
\cf6                     ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\cf4 \
\cf6                     ON CONFLICT (camis, inspection_date) DO UPDATE SET\cf4 \
\cf6                         dba = EXCLUDED.dba,\cf4 \
\cf6                         boro = EXCLUDED.boro,\cf4 \
\cf6                         building = EXCLUDED.building,\cf4 \
\cf6                         street = EXCLUDED.street,\cf4 \
\cf6                         zipcode = EXCLUDED.zipcode,\cf4 \
\cf6                         phone = EXCLUDED.phone,\cf4 \
\cf6                         cuisine_description = EXCLUDED.cuisine_description,\cf4 \
\cf6                         grade = EXCLUDED.grade,\cf4 \
\cf6                         grade_date = EXCLUDED.grade_date,\cf4 \
\cf6                         inspection_type = EXCLUDED.inspection_type,\cf4 \
\cf6                         critical_flag = EXCLUDED.critical_flag,\cf4 \
\cf6                         record_date = EXCLUDED.record_date,\cf4 \
\cf6                         latitude = EXCLUDED.latitude,\cf4 \
\cf6                         longitude = EXCLUDED.longitude,\cf4 \
\cf6                         community_board = EXCLUDED.community_board,\cf4 \
\cf6                         council_district = EXCLUDED.council_district,\cf4 \
\cf6                         census_tract = EXCLUDED.census_tract,\cf4 \
\cf6                         bin = EXCLUDED.bin,\cf4 \
\cf6                         bbl = EXCLUDED.bbl,\cf4 \
\cf6                         nta = EXCLUDED.nta\cf4 \
\cf6                 """\cf4 , (\
                    camis, dba, boro, building, street, zipcode, phone, inspection_date,\
                    critical_flag, record_date, latitude, longitude, community_board,\
                    council_district, census_tract, bin_val, bbl, nta, cuisine_description,\
                    grade, grade_date, inspection_type\
                ))\
                cur.execute(\cf6 """\cf4 \
\cf6                     INSERT INTO violations (\cf4 \
\cf6                         camis, inspection_date, violation_code, violation_description\cf4 \
\cf6                     ) VALUES (%s, %s, %s, %s)\cf4 \
\cf6                     ON CONFLICT DO NOTHING\cf4 \
\cf6                 """\cf4 , (\
                    camis, inspection_date, violation_code, violation_description\
                ))\
        
\f0\b \cf2 except
\f1\b0 \cf4  psycopg2.Error 
\f0\b \cf2 as
\f1\b0 \cf4  e:\
            logger.error(\cf6 "Error inserting record: %s"\cf4 , e)\
            conn.rollback()\
\
    conn.commit()\
    offset += limit\
    total_rows_fetched += len(data)\
    logger.info(\cf6 "Rows fetched: %s, Total rows so far: %s"\cf4 , len(data), total_rows_fetched)\
\
conn.close()\
}