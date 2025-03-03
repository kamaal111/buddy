async function refreshTokenIfExpired() {
    const baseURL = pm.environment.get("base_url")
    if (!baseURL) throw new Error("No base URL defined")

    const refreshToken = pm.environment.get("refresh_token")
    if (!refreshToken) throw new Error("No refresh token defined")

    const accessToken = pm.environment.get("access_token")
    if (!accessToken) throw new Error("No access token token defined")

    const expiryTimestamp = pm.environment.get("token_expiry_timestamp")
    if (!expiryTimestamp) throw new Error("No expiry timestamp defined")

    if (Number.isNaN(Number(expiryTimestamp))) throw new Error("Expiry timestamp is not a valid number")

    const now = parseInt((new Date()).getTime() / 1_000, 10)
    const shouldRefresh = (Number(expiryTimestamp) - now) < 30
    console.log("🐸🐸🐸 times", {now, expiryTimestamp, shouldRefresh})
    if (!shouldRefresh) return

    const requestOptions = {
        url: `${baseURL}/app-api/v1/auth/refresh`,
        method: "POST",
        header: {"Content-Type": "application/json", "Authorization": `Bearer ${accessToken}`},
        body: {mode: 'raw', raw: JSON.stringify({refresh_token: refreshToken})}
    }
    const response = await pm.sendRequest(requestOptions)
    const jsonResponse = response.json()
    if (response.code !== 200) throw new Error(`Invalid response; response='${JSON.stringify(jsonResponse)}'`)
    if (!jsonResponse.access_token) throw new Error("Refresh did not return access token")
    if (!jsonResponse.expiry_timestamp) throw new Error("Refresh did not return expiry timestamp")

    pm.environment.set("access_token", jsonResponse.access_token)
    pm.environment.set("token_expiry_timestamp", jsonResponse.expiry_timestamp)
}

module.exports = { refreshTokenIfExpired }
