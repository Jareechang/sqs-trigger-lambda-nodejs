exports.handler = async function (event, context) {
    throw new Error('Error out');
    console.log("EVENT: \n" + JSON.stringify(event, null, 2));
}
