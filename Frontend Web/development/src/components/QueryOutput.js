import React from 'react';

import Container from 'react-bootstrap/Container';
import Button from 'react-bootstrap/Button';
import Alert from 'react-bootstrap/Alert';
import Card from 'react-bootstrap/Card';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';

class QueryOutput extends React.Component {
    render = () => {
        switch (this.props.type) {
            case 'NONE':
                return <Container></Container>;
            case 'RESULT':
                var previousButton = <div></div>;
                var nextButton = <div></div>;
                
                if (this.props.previous) {
                    previousButton = <Button variant="primary" style={{marginTop: '2em'}} onClick={this.props.callPrevious}>Previous</Button>;
                }
                
                if (this.props.next) {
                    nextButton = <Button variant="primary" style={{marginTop: '2em'}} onClick={this.props.callNext}>Next</Button>;
                }
                
                return (
                    <div>
                        {this.props.payload.map(packet => 
                            <Container style={{textAlign: 'left'}}>
                                <Card border="info" style={{marginTop: '0.5em'}}>
                                    <Card.Body style={{color: 'black'}}>
                                        <Row>
                                            <Col sm={2}><b>Frequency:</b></Col>
                                            <Col sm={10}><kbd>{packet.carrierfreq} MHz</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>Bitrate:</b></Col>
                                            <Col sm={10}><kbd>{packet.bitrate} kbps</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>Modulation:</b></Col>
                                            <Col sm={10}><kbd>{packet.modulation}</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>Sync words:</b></Col>
                                            <Col sm={10}><code>{packet.syncwords}</code></Col>
                                                <hr />
                                            <Col sm={2}><b>Deviation:</b></Col>
                                            <Col sm={10}><kbd>{packet.frequencydeviation} kHz</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>RSSI:</b></Col>
                                            <Col sm={10}><kbd>{packet.rssi}</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>Model:</b></Col>
                                            <Col sm={10}><kbd>{packet.model}</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>Created:</b></Col>
                                            <Col sm={10}><kbd>{new Date(parseInt(packet.timestamp)).toUTCString()}</kbd></Col>
                                                <hr />
                                            <Col sm={2}><b>Payload:</b></Col>
                                            <Col sm={10}><code>{packet.data}</code></Col>
                                        </Row>
                                    </Card.Body>
                                </Card>
                            </Container>)}
                        <Row style={{marginTop: '2em'}}>
                            <Col sm={6}>
                                {previousButton}
                            </Col>
                            <Col sm={6}>
                                {nextButton}
                            </Col>
                        </Row>
                    </div>
                );
            case 'EMPTY':
                return (
                    <Alert variant="info" style={{marginTop: '2em'}}>
                        <Alert.Heading>No results :(</Alert.Heading>
                        <p>Try again using <kbd>%</kbd></p>
                    </Alert>
                );
            case 'ERROR':
                return (
                    <Alert variant="danger" style={{marginTop: '2em'}}>
                        <Alert.Heading>Error :(</Alert.Heading>
                        <p>{this.props.payload}</p>
                    </Alert>
                );
            case 'NONE':
            default:
                return <Container></Container>;
        }
    };
}

export default QueryOutput;
