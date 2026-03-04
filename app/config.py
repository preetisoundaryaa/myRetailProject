import os


class Settings:
    ENV = os.getenv("APP_ENV", "dev")
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

    # For this demo app we keep data in memory, but this keeps the interface ready
    # in case we move inventory to a shared store later.
    DATA_BACKEND = os.getenv("DATA_BACKEND", "memory")


settings = Settings()
