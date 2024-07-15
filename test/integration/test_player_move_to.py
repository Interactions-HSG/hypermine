import requests

TIMEOUT = 3



def _player_move_to_post(data: dict):
    # Configuration for the circle and HTTP request
    url = "http://localhost:9090/api/v1/player/move_to"
    headers = {"Content-Type": "application/json"}
    # {"x":0.00099999993108213,"y":-0.5,"z":-0.39000001549721}
    # {"x":13.996999740601,"y":-0.5,"z":14.021000862122}

    response = requests.post(url, json=data, headers=headers)
    # Print the response
    return response

# def _player_name_delete():
#     # Configuration for the circle and HTTP request
#     url = "http://localhost:9090/api/v1/player/name"
#     headers = {"Content-Type": "application/json"}
#     response = requests.delete(url, json={}, headers=headers, timeout=TIMEOUT)
#     return response

def test_player_move_to_post_fail():
    
    data = {"location" : {
        "x":0,
        "y":-0.5,
        "a":0.5
        }
    }
    t_out = _player_move_to_post(data)
    expected_response_code = 400
    assert t_out.status_code == expected_response_code, f"was expecting status code {expected_response_code}, got {t_out.status_code}"

def test_player_move_to_post_success():
    name_url = "http://localhost:9090/api/v1/player/name"
    name_headers = {"Content-Type": "application/json"}
    data = {"name" : "agent0"}
    # name_response = requests.post(name_url, json=data, headers=name_headers, timeout=TIMEOUT)
    name_response = requests.post(name_url, json=data, headers=name_headers)
    print(f"Sent player name: {data}, Response: {name_response.status_code}, {name_response.text}")

    assert name_response.status_code == 200
    
    data = {"location" : {
        "x":0,
        "y":-0.5,
        "z":0.5
        }
    }
    t_out = _player_move_to_post(data)
    expected_response_code = 200
    assert t_out.status_code == expected_response_code, f"was expecting status code {expected_response_code}, got {t_out.status_code}"


def run_tests():
    # test_player_move_to_post_fail()
    test_player_move_to_post_success()
