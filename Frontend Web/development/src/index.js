import React from 'react';
import ReactDOM from 'react-dom';
import App from './components/App';
import config from './config.json'
import 'bootstrap/dist/css/bootstrap.min.css';
import './index.css';

ReactDOM.render(
    <React.StrictMode>
        <App config={config}/>
    </React.StrictMode>,
    document.getElementById('root')
);

