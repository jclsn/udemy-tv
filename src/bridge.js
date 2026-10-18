// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

// Runs in the hidden bridge page on the Udemy origin, after qwebchannel.js.
// Requests made here go through Chromium's network stack with the page's cookies,
// which is what gets them past Cloudflare.

(function () {
    if (window.__udtv) {
        return;
    }

    window.__udtv = {};

    new QWebChannel(qt.webChannelTransport, function (channel) {
        const endpoint = channel.objects.udtvBridge;

        window.__udtv.fetch = function (id, method, url, body, headers, anonymous) {
            const init = {
                method: method,
                credentials: anonymous ? "omit" : "include",
                cache: "no-store",
                headers: headers || {},
            };

            if (body) {
                init.body = body;
            }

            fetch(url, init)
                .then(function (response) {
                    return response.text().then(function (text) {
                        endpoint.deliver(id, response.status, text);
                    });
                })
                .catch(function (error) {
                    endpoint.deliver(id, 0, String(error));
                });
        };

        endpoint.attach();
    });
})();
