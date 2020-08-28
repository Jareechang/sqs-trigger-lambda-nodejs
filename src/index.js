function parseSqsBodyMessage(sqsRecord) {
    const body = sqsRecord && sqsRecord.body;
    let result = {};
    try {
        result = JSON.parse(body);
    } catch (ex) {
        console.error('Error parsing sqs message body: ', ex);
    }

    return result;
}

exports.handler = async function (event, context) {
    const records = event['Records'] || [];

    const errorRecords = records.filter((record) => {
        const bodyMessage = parseSqsBodyMessage(record);
        return bodyMessage.type === 'ERROR';
    });

    if (errorRecords.length > 0) {
        throw new Error('Received error from SQS message body');
    }

    console.log('SQS Records: ', JSON.stringify(records, null, 4));
}
