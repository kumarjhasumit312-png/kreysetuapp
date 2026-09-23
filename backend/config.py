class Config:
    SECRET_KEY = 'kreysetu-secret-key-change-this-later'
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://root:1234@localhost/kreysetu_db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False