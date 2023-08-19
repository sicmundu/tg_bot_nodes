const express = require('express');
const app = express();
const PORT = 3003;
const { exec } = require('child_process');
require('dotenv').config();
const NodeCache = require( "node-cache" );
const cache = new NodeCache({ stdTTL: 60, checkperiod: 120 });

const TOKEN = process.env.TOKEN;

app.use((req, res, next) => {
    // Получаем токен из заголовков запроса
    const authorizationHeader = req.headers['authorization'];
    const receivedToken = authorizationHeader && authorizationHeader.replace('Bearer ', '');



    // Проверяем токен
    if (!receivedToken) {
        console.error('No token provided.');
        return res.status(401).send('No token provided.');
    }

    if (receivedToken !== TOKEN) {
        console.error('Invalid token provided.');
        return res.status(401).send('Invalid token.');
    }

    console.log('Valid token provided. Continuing request processing.');

    // Токен валиден, продолжаем обработку запроса
    next();
});



function checkNodeStatus(nodeName, checkType, callback) {
    let command;
    if (checkType === 'docker') {
        command = `docker ps -q --filter "status=running" --filter "name=${nodeName}"`;
    } else if (checkType === 'systemctl') {
        command = `systemctl is-active ${nodeName}`;
    } else {
        console.error(`Invalid check type: ${checkType}`);
        callback(false);
        return;
    }

    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            callback(false);
            return;
        }

        if (checkType === 'docker') {
            callback(stdout.trim() !== '');
        } else if (checkType === 'systemctl') {
            callback(stdout.trim() === 'active');
        } else {
            console.error(`Invalid check type: ${checkType}`);
            callback(false);
        }

        cache.set(nodeName, isRunning, 60);
    });
}

app.get('/server_status', (req, res) => {
    // Получение свободного места и общего объема диска
    exec("df -h | grep ' /$'", (error, stdout, stderr) => {
        if (error || !stdout) {
            return res.status(500).send("Error retrieving disk space");
        }
        
        const parts = stdout.trim().split(/\s+/);
        const total_space = parts[1];  // Общий объем диска
        const free_space = parts[3];   // Свободное место

        // Получение использования RAM и общего объема RAM
        exec("free -m | grep Mem | awk '{print $3, $2}'", (error, ram_stdout, stderr) => {
        const [used_ram, total_ram] = ram_stdout.trim().split(' ').map(val => parseFloat(val));

             res.send({
            free_space: free_space,
            total_space: total_space,
            used_ram: used_ram, // Возвращаем в MB
            total_ram: total_ram
        });
        });
    });
});

app.get('/node_status/:nodeName', (req, res) => {
    const nodeName = req.params.nodeName;
    const checkType = req.query.check_type;

    checkNodeStatus(nodeName, checkType, (isRunning) => {
        res.send({
            node: nodeName,
            status: isRunning ? 'Running' : 'Not Running'
        });
    });
});


app.get('/status', (req, res) => {
    res.send({status: 'OK'});
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
