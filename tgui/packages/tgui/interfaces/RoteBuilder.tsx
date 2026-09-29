// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { InfinitePlane } from 'tgui-core/components';

import { Window } from '../layouts';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';

export const RoteBuilder = (props) => {
    const { act, data } = useBackend();

    return(
        <Window width={1200} height={800} title="Rote Builder">
            <Window.Content
                style={{
                    backgroundImage: 'none',
                }}
            >
                <InfinitePlane
                    width="100%"
                    height="100%"
                    backgroundImage={resolveAsset('grid_background.png')}
                    imageWidth={900}
                    initialLeft={0}
                    initialTop={0}
                >

                </InfinitePlane>
            </Window.Content>
        </Window>
    );
};
