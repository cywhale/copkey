export default function (body, ) {
        return `
                <!DOCTYPE html>
                <html>
                        <head>
                                <meta charset="UTF-8">
                                <meta name="viewport" content="width=device-width, initial-scale=1$
                                <title>Copkey App</title>
                        </head>
                        <body>
                                <div id="app">${body}</div>
                                <!--script src="/App.js"></script-->
                        </body>
                </html>
        `;
}

