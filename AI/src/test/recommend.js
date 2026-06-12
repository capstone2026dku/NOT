export async function get_preference(menu) {
    const res = await fetch("http://localhost:8000/preference", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            menu
        })
    });

    return await res.json();
}

export async function get_weather() {
    const res = await fetch("http://localhost:8000/weather", {
        method: "GET",
    });

    return await res.json();
}

export async function get_cooking_time(menu, orderCount) {
    const res = await fetch("http://localhost:8000/cooking_time", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            menu,
            orderCount
        })
    });

    return await res.json();
}

export async function update_cooking_time(menu, orderCount, actualTime) {
    const res = await fetch("http://localhost:8000/cooking_time_update", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            menu,
            orderCount,
            actualTime
        })
    });

    return await res.json();
}