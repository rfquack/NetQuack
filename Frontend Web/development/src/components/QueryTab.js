import React from 'react';

import Container from 'react-bootstrap/Container';
import Button from 'react-bootstrap/Button';
import Alert from 'react-bootstrap/Alert';
import Form from 'react-bootstrap/Form';
import Col from 'react-bootstrap/Col';
import Row from 'react-bootstrap/Row';

import QueryOutput from './QueryOutput';

class QueryTab extends React.Component {
    constructor(props) {
        super(props);

        this.fields = [];
        this.tokens = [];
        this.current_token_index = -1;
        this.query_execution_id = undefined;
        
        this.state = {
            data:        '',
            date_from:   '',
            date_to:     '',
            frequency:   '',
            bitrate:     '',
            modulation:  '',
            type:        'NONE',    // NONE | EMPTY | RESULT | ERROR
            payload:     ''
        }
    };
    
    changeHandler = (event) => {
        const target = event.target;
        const name = target.name;
        const value = target.type === 'checkbox' ? target.checked : target.value;

        this.setState({
            [name]: value,
        });
    };
    
    submitHandler = (event) => {
        event.preventDefault();

        fetch(`${this.props.config.API_URL}/query?data=${encodeURIComponent(this.state.data)}` +
                                                 `&date_from=${this.state.date_from}&date_to=${this.state.date_to}` +
         		                                 `&latitude_from=${this.props.box.latitudeFrom}&longitude_from=${this.props.box.longitudeFrom}` +
                                 			     `&latitude_to=${this.props.box.latitudeTo}&longitude_to=${this.props.box.longitudeTo}` +
                                			     `&frequency=${this.state.frequency}&bitrate=${this.state.bitrate}&modulation=${this.state.modulation}`, { method: 'POST' })
        .then(response => { return response.json(); })
        .then(data => {
            if (data.message) {
                this.setState({
                    type: 'ERROR',
                    payload: data.message
                });
            } else {
                this.handleQueryResults(data.query_execution_id);
            }
        });
    };
    
    handleQueryResults = (query_execution_id, token) => {
        var retrieve_url = `${this.props.config.API_URL}/query?query_execution_id=${encodeURIComponent(query_execution_id)}`;
        if (token) {
                retrieve_url += `&next_token=${encodeURIComponent(token)}`;
        }

        fetch(retrieve_url)
        .then(response => { return response.json(); })
        .then(data => {
            if (data.message) {
                this.setState({
                    type: 'ERROR',
                    payload: data.message
                });
            } else if (data.result.length === 1) {
                this.setState({
                    type: 'EMPTY'
                });
            } else {
                // Results are in CSV: first row contains fields
                // "token" parameter undefined -> we are on the first page
                // received "data.next_token" as empty string -> we are on the last page
	            var slice_index = 0;

                if (!token) {
                    slice_index = 1;
		                
                    this.fields = data.result[0].split(',');
                    this.tokens = [null];
                    this.current_token_index = 0;
                    this.query_execution_id = query_execution_id;
                }
			        
                // Then convert into Javascript objects
                var result = [];
                for (var row of data.result.slice(slice_index)) {
                    var values = row.split(',');
                    var local_object = {};
                    for (var i in values) {
                        local_object[this.fields[i]] = values[i];
                    }
                    result.push(local_object);
                }
		        
                // Include token for next page if it is not already present
                if (!this.tokens.includes(data.next_token)) {
                    this.tokens.push(data.next_token)
                }

                this.setState({
                    type: 'RESULT',
                    payload: result,
                    previous: (this.current_token_index > 0),
                    next: (data.next_token !== "")
                });
            }
        });
    };
    
    previousPage = () => {
        if (this.current_token_index > 0) {
            --this.current_token_index;
            var query_execution_id = this.query_execution_id;
            var next_token         = this.tokens[this.current_token_index];
            this.handleQueryResults(query_execution_id, next_token);
        }
    }

    nextPage = () => {
        if (this.tokens[this.current_token_index+1] !== "") {
            ++this.current_token_index;
            var query_execution_id = this.query_execution_id;
            var next_token         = this.tokens[this.current_token_index];
            this.handleQueryResults(query_execution_id, next_token);
        }
    }
    
    render = () => {
        return (
            <Container style={{width: '100%', marginTop: '2.6em', paddingTop: '1.2em', paddingBottom: '1em', borderRadius: '1em'}}>
                <Alert variant="primary">
                    <p class="lead" style={{textAlign: 'left'}}>
                        Query for a packet
                    </p>
                    <Form onSubmit={this.submitHandler}>
                        <p style={{textAlign: 'left', fontSize: '0.9em'}}>Type a hexadecimal string, use <kbd>%</kbd> as wildcard.</p>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Query:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="text" name="data" onChange={this.changeHandler} placeholder="AAAAAAAAA%" />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Date <small>(from ... to)</small>:</Form.Label>
                            <Col sm={5}>
                                <Form.Control type="date" name="date_from" onChange={this.changeHandler} />
                            </Col>
                            <Col sm={5}>
                                <Form.Control type="date" name="date_to" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>

                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Latitude <small>(from ... to)</small>:</Form.Label>
                            <Col sm={5}>
                                <Form.Control type="number" step="0.000001" min="-90" max="90" value={this.props.box.latitudeFrom} name="latitude_from" onChange={this.changeHandler} />
                            </Col>
                            <Col sm={5}>
                                <Form.Control type="number" step="0.000001" min="-90" max="90" value={this.props.box.latitudeTo} name="latitude_to" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Longitude <small>(from ... to)</small>:</Form.Label>
                            <Col sm={5}>
                                <Form.Control type="number" step="0.000001" min="-180" max="180" value={this.props.box.longitudeFrom} name="longitude_from" onChange={this.changeHandler} />
                            </Col>
                            <Col sm={5}>
                                <Form.Control type="number" step="0.000001" min="-180" max="180" value={this.props.box.longitudeTo} name="longitude_to" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Frequency <small>(MHz)</small>:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="number" step="0.1" min="0" max="3000" name="frequency" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Bitrate <small>(kbps)</small>:</Form.Label>
                            <Col sm={10}>
                                <Form.Control type="number" step="1" min="0" max="5000" name="bitrate" onChange={this.changeHandler} />
                            </Col>
                        </Form.Group>
                                        
                        <Form.Group as={Row} style={{marginBottom: '0.4em'}}>
                            <Form.Label column sm={2}>Modulation:</Form.Label>
                            <Col sm={10}>
                                <Form.Control as="select" name="modulation" onChange={this.changeHandler}>
                                    <option value=""></option>
                                    <option value="OOK">OOK</option>
                                    <option value="FSK2">FSK2</option>
                                    <option value="GFSK">GFSK</option>
                                </Form.Control>
                            </Col>
                        </Form.Group>
                                        
                        <Button variant="primary" as="input" type="submit" value="Search"></Button>

                    </Form>
                </Alert>
                <QueryOutput
                    type={this.state.type}
                    payload={this.state.payload}
                    previous={this.state.previous}
                    next={this.state.next}
                    callPrevious={this.previousPage}
                    callNext={this.nextPage} />
            </Container>
        );
    };
}

export default QueryTab;
