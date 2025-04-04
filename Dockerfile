# Use a lightweight Python image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy your Python script into the container
COPY weather_crawler.py .

# Install dependencies
RUN pip install requests pymongo

# Set environment variables (override at runtime if needed)
ENV MONGO_URL=mongodb://localhost:27017/
ENV WEATHERAPI_KEY=e8c8fbdbbbc94662b95120359250304

# Run the script
CMD ["python", "weather_crawler.py"]
