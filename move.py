import requests
import time
import math

# Configuration for the circle and HTTP request
radius = 5.0  # Radius of the circle
url = "http://localhost:9090/api/v1/player/position"
headers = {"Content-Type": "application/json"}

def get_starting_position():
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        position_data = response.json()
        return position_data['x'], position_data['y'], position_data['z']
    else:
        raise Exception(f"Failed to get starting position: {response.status_code}, {response.text}")

def run_in_circle(center_x, center_y, center_z):
    angle = 0.0
    prev_x = center_x + radius * math.cos(angle)
    prev_z = center_z + radius * math.sin(angle)
    
    while True:
        # Calculate new position
        angle += 0.1
        x = center_x + radius * math.cos(angle)
        z = center_z + radius * math.sin(angle)
        
        # Calculate deltas
        delta_x = x - prev_x
        delta_z = z - prev_z
        
        # Update previous position
        prev_x = x
        prev_z = z
        
        # Create delta position JSON
        delta_position = {"position": {"x": delta_x, "y": 0, "z": delta_z}}
        
        # Make the HTTP request
        response = requests.post(url, json=delta_position, headers=headers)
        
        # Print the response
        print(f"Sent delta position: {delta_position}, Response: {response.status_code}, {response.text}")
        
        # Sleep for a short duration to simulate time passage
        time.sleep(0.1)

if __name__ == "__main__":
    try:
        # Get the starting position
        start_x, start_y, start_z = get_starting_position()
        print(f"Starting position: x={start_x}, y={start_y}, z={start_z}")
        
        # Run in a circle around the starting position
        run_in_circle(start_x, start_y, start_z)
    except Exception as e:
        print(f"Error: {e}")
