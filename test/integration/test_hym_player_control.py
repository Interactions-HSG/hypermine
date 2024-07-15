import requests

TIMEOUT = 3

def _player_name_post(name: str):
    # Configuration for the circle and HTTP request
    url = "http://localhost:9090/api/v1/player/name"
    headers = {"Content-Type": "application/json"}
    data = {"name" : name}
    response = requests.post(url, json=data, headers=headers, timeout=TIMEOUT)
    # Print the response
    print(f"Sent player name: {data}, Response: {response.status_code}, {response.text}")
    return response

def _player_name_delete(name: str):
    # Configuration for the circle and HTTP request
    url = "http://localhost:9090/api/v1/player/name"
    headers = {"Content-Type": "application/json"}
    response = requests.delete(url, json={}, headers=headers, timeout=TIMEOUT)
    return response

def test_player_name_post_fail():
    t_out = _player_name_post("name-does-not-exist")
    assert t_out.status_code == 400

def test_player_name_post_success():
    t_out = _player_name_post("agent0")
    assert t_out.status_code == 200

def test_player_name_delete_success():
    t_out = _player_name_post("agent0")
    assert t_out.status_code == 200

def run_tests():
    # test_player_name_post_fail()
    test_player_name_post_success()
