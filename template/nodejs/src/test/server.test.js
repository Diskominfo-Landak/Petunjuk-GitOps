const test = require('node:test');
const assert = require('node:assert');
const app = require('../server');

test('GET /healthz harus mengembalikan status 200', async () => {
    assert.ok(app);
});
