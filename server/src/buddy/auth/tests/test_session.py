from http import HTTPStatus


def test_session(client, default_user_credentials, default_user_login):
    session_response = client.get(
        "/app-api/v1/auth/session",
        headers={
            "authorization": f"Bearer {default_user_login.access_token}",
        },
    )
    session_json = session_response.json()

    assert session_response.status_code == HTTPStatus.OK
    assert session_json["detail"] == "OK"
    assert session_json["user"] == {
        "email": default_user_credentials.email,
        "tier": "FREE",
    }
    assert session_json["available_models"] == [
        {
            "provider": "openai",
            "key": "gpt-4o",
            "display_name": "GPT-4o",
            "description": "Excels at fast, accurate, and multimodal AI interactions.",
        }
    ]
