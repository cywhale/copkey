export default function (page, data) {
    let jsondt = data ? JSON.stringify(data) : '""';
    return `
        <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>Copkey App</title>
                    <!--link rel="stylesheet" href="/styles/${cssFile}" /-->
                    <script>
                        const SERV_DATA = ${jsondt};
                    </script>
                </head>
                <body>
                    <div id="app">${body}</div>
                     <!--script src="/${page}.js"></script-->
                </body>
            </html>
    `
}


