import json 
import time 
import random 
from google.cloud import pubsub_v1


project_id = "YOUR_PROJECT_ID"
topic_id = "YOUR_TOPIC_NAME"

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)


def generate_data():
    return {
        "user_id": random.randint(1, 1000), 
        "action": random.choice(["click", "view", "purchase"]),
        "timestamp": time.time()
    }

while True:
    data = json.dumps(generate_data()).encode("utf-8")
    publisher.publish(topic_path, data)  
    print(f"Published message: {data}")
    time.sleep(3)


    