import React from 'react';

import Container from 'react-bootstrap/Container';
import Button from 'react-bootstrap/Button';
import Alert from 'react-bootstrap/Alert';
import Form from 'react-bootstrap/Form';
import Col from 'react-bootstrap/Col';
import Row from 'react-bootstrap/Row';

import RegisterOutput from './RegisterOutput';

class RegisterTab extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            name:       '',
            latitude:   '',
            longitude:  '',
            key:        '',
            type:       'NONE',    // NONE | RESULT | ERROR
            payload:    ''
        }
    }
    
    changeHandler = (event) => {
        const target = event.target;
        const name = target.name;
        const value = target.type === 'checkbox' ? target.checked : target.value;

        this.setState({
            [name]: value,
        });
        
        if (target.type === 'checkbox') {
            if (target.checked) {
                document.getElementById('key-container').style.display = 'flex';
            } else {
                document.getElementById('key-container').style.display = 'none';
            }
        }
    };
    
    handleForm = (event) => {
        event.preventDefault();
        
        var name      = this.state.name;
        var latitude  = this.props.marker.latitude;
        var longitude = this.props.marker.longitude;
        var key       = this.state.key;
        
        if (this.state.key) {    // update existing dongle
            fetch('/api/update', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    latitude,
                    longitude,
                    key
                })
            })
            .then(response => { return response.json(); })
            .then(data => {
                this.setState({
                    type: 'RESULT',
                    payload: data.message
                });
            });
        } else {    // register new dongle
            fetch('/api/register', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    latitude,
                    longitude
                })
            })
            .then(response => { return response.blob(); })
            .then(data => {
                // JSON response = an error has occurred
                // blob response = files with certificates
                try {
                    var response = JSON.parse(data.text());
                    this.setState({
                        type: 'ERROR',
                        payload: data.message
                    });
                } catch (error) {
                    var output = (
<div>
    Dongle created successfully. The zip archive contains the following files:
    <ul>
        <li> rfquack_certificates.h </li>
        <li> {name}-certificate.pem.crt </li>
        <li> {name}-public.pem.key </li>
        <li> {name}-private.pem.key </li>
        <li> rootCA.pem </li>
    </ul>
                                                
    In order to use your dongle, copy rfquack_certificates.h into src/ and put these definitions into main.cpp:
<br />
<code>
    #define RFQUACK_UNIQ_ID "{name}" <br />
    #define RFQUACK_TOPIC_PREFIX RFQUACK_UNIQ_ID <br />
    #define RFQUACK_MQTT_BROKER_HOST "{this.props.config.MQTT_HOST}" <br />
    #define RFQUACK_MQTT_BROKER_PORT {this.props.config.MQTT_PORT} <br />
    #define RFQUACK_MQTT_BROKER_SSL
</code>
<br />
                                                
In order to interact with your dongle from the shell, use this command:
<br />
<kbd>rfquack mqtt -i {name}Shell -H {this.props.config.MQTT_HOST} -P {this.props.config.MQTT_PORT} -a rootCA.pem -c {name}-certificate.pem.crt -k {name}-private.pem.key</kbd>
<br />
If you want to update your dongle later, run <kbd>sha512sum {name}-private.pem.key</kbd> and use the output as authentication token.
</div>
                    );
                    
                    var element = document.createElement('a');
                    var url = window.URL.createObjectURL(data)
                    element.setAttribute('href', url);
                    element.setAttribute('download', 'dongle.zip');
                    element.style.display = 'none';
                    document.body.appendChild(element);
                    element.click();
                    document.body.removeChild(element);
                    window.URL.revokeObjectURL(url);
                    
                    this.setState({
                        type: 'RESULT',
                        payload: output
                    });
                }
            });
        }
    }
    
    render = () => {
        return (
            <Container style={{width: '100%', marginTop: '2.6em', paddingTop: '1.2em', paddingBottom: '1em', borderRadius: '1em'}}>
                <Alert variant="primary">
                    <p class="lead" style={{textAlign: 'left'}}>
                        Register a dongle
                    </p>
                    <Form onSubmit={this.handleForm}>
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Name:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="text" name="name" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Latitude:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="number" step="0.000001" min="-90" max="90" value={this.props.marker.latitude} name="latitude" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Longitude:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="number" step="0.000001" min="-180" max="180" value={this.props.marker.longitude} name="longitude" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Col sm={2}>
                                <Form.Check 
                                    type="checkbox"
                                    name="update"
                                    label="Update"
                                    onChange={this.changeHandler} 
                                />
                            </Col>
                        </Form.Group>
    
                        <Form.Group as={Row} id="key-container" style={{marginBottom: '0.4em', display: 'none'}}>
                            <Form.Label column sm={2}>Dongle key:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="text" name="key" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Button variant="primary" as="input" type="submit" value="Register"></Button>
                    </Form>
                </Alert>
                <RegisterOutput type={this.state.type} payload={this.state.payload}/>
            </Container>
        );
    };
}

export default RegisterTab;
