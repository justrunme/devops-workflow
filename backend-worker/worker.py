import redis
import time
import os
import json
import markdown2

# Connect to Redis
redis_client = redis.Redis(host=os.environ.get('REDIS_HOST', 'localhost'), port=6379, db=0)

def process_task(task_id, task_data):
    print(f"Processing task: {task_id}")
    try:
        html_content = markdown2.markdown(task_data['markdown'])
        task_data['status'] = 'completed'
        task_data['html'] = html_content
        task_data['completedAt'] = time.strftime("%Y-%m-%dT%H:%M:%S%z", time.gmtime())
        redis_client.set(task_id, json.dumps(task_data))
        print(f"Task {task_id} completed successfully.")
    except Exception as e:
        print(f"Error processing task {task_id}: {e}")
        task_data['status'] = 'failed'
        task_data['error'] = str(e)
        redis_client.set(task_id, json.dumps(task_data))

def main():
    print("Backend worker started...")
    while True:
        # This is a simple polling mechanism. In a real-world scenario,
        # you might use Redis Pub/Sub or blocking lists (BLPOP) for more efficiency.
        tasks = redis_client.keys('*') # In a real app, you'd use a more specific pattern
        for task_id in tasks:
            task_id = task_id.decode('utf-8')
            task_data = redis_client.get(task_id)
            if task_data:
                task = json.loads(task_data)
                if task.get('status') == 'pending':
                    process_task(task_id, task)
        time.sleep(5) # Poll every 5 seconds

if __name__ == "__main__":
    main()
