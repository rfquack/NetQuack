import React from 'react';

import Image from 'react-bootstrap/Image';
import Tab from 'react-bootstrap/Tab';
import Nav from 'react-bootstrap/Nav';

import OLMapFragment from './OLMapFragment';
import RegisterTab from './RegisterTab';
import QueryTab from './QueryTab';
import logo from '../assets/logo.png';

import './App.css';

class App extends React.Component {
    constructor(props) {
        super(props);
        
        this.state = {
            marker: {
                latitude:   0,
                longitude:  0,
            },
            box: {
                latitudeFrom:   0,
                latitudeTo:     0,
                longitudeFrom:  0,
                longitudeTo:    0,
            }
        }
    }
    
    setBox = (latitudeFrom, latitudeTo, longitudeFrom, longitudeTo) => {
        this.setState({
            box: {
                latitudeFrom,
                latitudeTo,
                longitudeFrom,
                longitudeTo
            }
        });
    }
    
    setMarker = (latitude, longitude) => {
        this.setState({
            marker: {
                latitude,
                longitude
            }
        });
    }
    
    render = () => {
        return (
            <div className="App">
                <header className="App-header">
                    <Image src={logo} className="App-logo" mb={4} alt="logo" />
                    <hr />
                    <h4>The search engine for <b>Radio Signals</b>.</h4>

                    <Tab.Container defaultActiveKey="#query">
                        <Nav variant="pills" className="justify-content-md-center" defaultActiveKey="#query">
                            <Nav.Item>
                                <Nav.Link href="#dongle">Dongle</Nav.Link>
                            </Nav.Item>
                            <Nav.Item>
                                <Nav.Link href="#query">Query</Nav.Link>
                            </Nav.Item>
                        </Nav>

                        <OLMapFragment config={this.props.config} setBox={this.setBox} setMarker={this.setMarker}/>
                        <Tab.Content>
                            <Tab.Pane eventKey="#dongle">
                                <RegisterTab config={this.props.config} marker={this.state.marker}/>
                            </Tab.Pane>
                            <Tab.Pane eventKey="#query">
                                <QueryTab config={this.props.config} box={this.state.box}/>
                            </Tab.Pane>
                        </Tab.Content>
                    </Tab.Container>
                </header>
            </div>
        );
    };
}

export default App;
