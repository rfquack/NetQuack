import React from 'react';

import Container from 'react-bootstrap/Container';
import Alert from 'react-bootstrap/Alert';

class RegisterOutput extends React.Component {
    render = () => {
        switch (this.props.type) {
            case 'NONE':
                return <Container></Container>;
            case 'RESULT':
                return (
                    <Alert variant="success" style={{textAlign: 'left'}}>
                        {this.props.payload}
                    </Alert>
                );
            case 'ERROR':
                return (
                    <Alert variant="danger" style={{marginTop: '2em'}}>
                        <Alert.Heading>Error :(</Alert.Heading>
                        <p>{this.props.payload}</p>
                    </Alert>
                );
            default:
                return <Container></Container>;
        }
    };
}

export default RegisterOutput;
