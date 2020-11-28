import React from 'react';
import Container from 'react-bootstrap/Container';
import marker from '../assets/marker.png';

// Start OpenLayers imports
import {
    Map,
    View
} from 'ol';

import {
    Tile as TileLayer,
    Vector as VectorLayer
} from 'ol/layer';

import {
    Vector as VectorSource,
    OSM as OSMSource
} from 'ol/source';

import Feature from 'ol/Feature';

import {
    defaults as DefaultControls
} from 'ol/control';

import {
    Style,
    Icon
} from 'ol/style';

import {
    Point
} from 'ol/geom';

import {
    fromLonLat,
    toLonLat
} from 'ol/proj';
// End OpenLayers imports

class OLMapFragment extends React.Component {
    constructor(props) {
        super(props);
        this.map = undefined;
        this.state = {
            height: window.innerWidth >= 992 ? window.innerHeight : 400
        }    
    }
    
    updateDimensions = () => {
        const height = window.innerWidth >= 992 ? window.innerHeight : 400;
        this.setState({ height });
    };

    componentDidMount = () => {
        const markerSource = new VectorSource();
        const dongleSource = new VectorSource();
        var markerStyle = new Style({
            image: new Icon({
                anchor: [0.5, 1],
                anchorXUnits: 'fraction',
                anchorYUnits: 'fraction',
                scale: 0.15,
                src: marker
            })
        });
        var view = new View({
            projection: 'EPSG:3857',
            center: fromLonLat([-0.1275, 51.507222]),
            zoom: 12
        })
        
        // Create an OpenLayer Map instance
        this.map = new Map({
            // Display the map in a div with id 'map'
            target: 'map',
            // Add layers for tiles and markers
            layers: [
                new TileLayer({
                    source: new OSMSource()
                }),
                new VectorLayer({
                    source: markerSource,
                    style: markerStyle,
                }),
                new VectorLayer({
                    source: dongleSource,
                    style: markerStyle,
                })
            ],
            // Add in the following map controls
            controls: DefaultControls(),
            // Render the tile layers in a map view with Mercator projection
            view: view
        });
        
        // Center view on user position
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(function (position) {
                view.setCenter(fromLonLat([position.coords.longitude, position.coords.latitude]));
            });
        }
        
        // Add a unique marker when clicking on the map
        this.map.on('singleclick', (event) => {
                var iconFeature = new Feature({ geometry: new Point(event.coordinate) });
                markerSource.clear();
                markerSource.addFeature(iconFeature);
                
                var latitude = toLonLat(event.coordinate)[1].toFixed(6);
                var longitude = toLonLat(event.coordinate)[0].toFixed(6);
                this.props.setMarker(latitude, longitude);
        });
        
        // Update coordinates when moving map
        setInterval(() => {
            var bottom = toLonLat(this.map.getCoordinateFromPixel([
                10,
                document.getElementById("map").clientHeight-10
            ]));
            var latitudeFrom = bottom[1].toFixed(6);
            var longitudeFrom = bottom[0].toFixed(6);
            
            var top = toLonLat(this.map.getCoordinateFromPixel([
                document.getElementById("map").clientWidth-10,
                10
            ]));
            var latitudeTo = top[1].toFixed(6);
            var longitudeTo = top[0].toFixed(6);
            
            this.props.setBox(latitudeFrom, latitudeTo, longitudeFrom, longitudeTo);
        }, 1000);
        
        // Add markers for existing dongles
        fetch(`${this.props.config.API_URL}/dongle`)
            .then(response => { return response.json(); })
            .then(data => {
                data.forEach(dongle => {
                    var icon = new Feature({ geometry: new Point(fromLonLat([dongle.longitude, dongle.latitude])) });
                    dongleSource.addFeature(icon);
                });
            });
	
        window.addEventListener('resize', this.updateDimensions);
    };
        
    componentWillUnmount = () => {
        window.removeEventListener('resize', this.updateDimensions);
    };
        
    render = () => {
        const style = {
            width: '100%',
            height: this.state.height,
            backgroundColor: '#cccccc',
        }
        return (
            <Container xs={12}>
                <div id='map' style={style}></div>
            </Container>
        )
    };
}

export default OLMapFragment;
