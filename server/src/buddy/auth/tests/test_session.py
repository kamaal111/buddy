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
            "provider": "google",
            "key": "gemini-2.0-flash-lite",
            "display_name": "Gemini 2.0 Flash-Lite",
            "description": "Lightning-fast and cheapest AI. Incredibly efficient reasoning model by Google.",
        },
        {
            "provider": "google",
            "key": "gemini-2.0-flash",
            "display_name": "Gemini 2.0 Flash",
            "description": "Lightning-fast AI. Incredibly efficient reasoning model by Google.",
        },
        {
            "provider": "openai",
            "key": "gpt-4o-mini",
            "display_name": "GPT-4o mini",
            "description": "GPT-4o Mini is great for lightweight, fast, and cost-effective AI tasks.",
        },
        {
            "provider": "openai",
            "key": "o3-mini",
            "display_name": "GPT-o3 mini",
            "description": "GPT-o3 Mini is a small reasoning model, providing high intelligence at the same cost.",
        },
        {
            "provider": "openai",
            "key": "gpt-4o",
            "display_name": "GPT-4o",
            "description": "Excels at fast, accurate, and multimodal AI interactions.",
        },
    ]
