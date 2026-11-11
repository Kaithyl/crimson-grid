// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Divider,
  DmIcon,
  Icon,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import { LoadingScreen } from '../../common/LoadingScreen';
import type { InstrumentInfo, PreferencesMenuData } from '../types';
import { useServerPrefs } from '../useServerPrefs';

const SPHERES = [
  { key: 'correspondence', name: 'Correspondence' },
  { key: 'entropy', name: 'Entropy' },
  { key: 'forces', name: 'Forces' },
  { key: 'life', name: 'Life' },
  { key: 'matter', name: 'Matter' },
  { key: 'mind', name: 'Mind' },
  { key: 'prime', name: 'Prime' },
  { key: 'spirit', name: 'Spirit' },
  { key: 'time', name: 'Time' },
];

type FociData = PreferencesMenuData & {
  instruments: Record<string, string>;
  discarded_instruments: string[];
  paradigm: number;
  instrument_discard_points: number;
  instrument_discard_points_spent: number;
};

function InstrumentIcon(props: {
  info: InstrumentInfo;
  size?: string;
  dimmed?: boolean;
}) {
  const { info, size = '48px', dimmed } = props;
  if (!info.icon || !info.icon_state) {
    return (
      <Box
        color="label"
        textAlign="center"
        style={{ height: size, lineHeight: size, opacity: dimmed ? 0.4 : 1 }}
      >
        {info.name}
      </Box>
    );
  }
  return (
    <Box style={{ opacity: dimmed ? 0.4 : 1 }}>
      <DmIcon
        icon={info.icon}
        icon_state={info.icon_state}
        height={size}
        width={size}
      />
    </Box>
  );
}

// Putting this here temporarily until everything here is moved to CSS
const DISCARDED_OUTLINE = '2px solid #d4af37';
const DISCARDED_GLOW = '0 0 6px rgba(212, 175, 55, 0.7)';

export function FociPage() {
  const serverData = useServerPrefs();
  const { act, data } = useBackend<FociData>();
  const [selectedSphere, setSelectedSphere] = useState<string | null>(null);

  if (!serverData) {
    return <LoadingScreen />;
  }

  const instruments = serverData.instruments || {};
  const sphere_slots = data.instruments || {};
  const discarded = new Set(data.discarded_instruments || []);
  const paradigm = data.paradigm ?? 0;
  const pointsAvailable = data.instrument_discard_points ?? 0;
  const pointsSpent = data.instrument_discard_points_spent ?? 0;
  const pointsRemaining = pointsAvailable - pointsSpent;

  const instrumentEntries = Object.entries(instruments).sort(
    ([, a], [, b]) => {
      const aInParadigm = !paradigm || (a.paradigms & paradigm) !== 0;
      const bInParadigm = !paradigm || (b.paradigms & paradigm) !== 0;
      if (aInParadigm === bInParadigm) {
        return 0;
      }
      return aInParadigm ? -1 : 1;
    },
  );

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Stack vertical align="center">
          <Stack.Item>
            <Box fontSize={1.5} bold textAlign="center">
              <span title="Any standard instrument may be used without any difficulty penalty, but matching an instrument with the primary Sphere of an effect awards a -1 difficulty reduction. Using a non-standard but in-paradigm instrument gives +1 diff, while outside of paradigm gives +2 diff.">
                Instruments
              </span>
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Stack justify="center">
              {Array.from({ length: pointsAvailable }, (_, i) => {
                const filled = i < pointsRemaining;
                return (
                  <Stack.Item key={i}>
                    <Icon
                      name="circle"
                      color={filled ? 'white' : 'rgba(255,255,255,0.18)'}
                      style={{ fontSize: '10px', margin: '0 1px' }}
                    />
                  </Stack.Item>
                );
              })}
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Box color="label" textAlign="center">
          {pointsRemaining >= 0 ? pointsRemaining : 0} / {pointsAvailable}{' '}
          discardable
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Box color="label" textAlign="center">
          <i>
            A mage must assign a standard instrument for each Sphere, but may
            have no less than seven unique instruments.
          </i>
        </Box>
        <Box color="label" textAlign="center">
          <i>
            Mystic paradigms transcend the need for 1 instrument for every dot
            past arete 2. (Technomancers begin discarding at arete 6)
          </i>
        </Box>
      </Stack.Item>

      {/* Spheres */}
      <Stack.Item>
        <Box
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            justifyContent: 'center',
            padding: '8px',
          }}
        >
          {SPHERES.map((sphere) => {
            const assignedPath = sphere_slots[sphere.key];
            const assignedInfo = assignedPath
              ? instruments[assignedPath]
              : undefined;
            const isSelected = selectedSphere === sphere.key;
            const isDiscarded = assignedPath
              ? discarded.has(assignedPath)
              : false;
            return (
              <Box
                key={sphere.key}
                style={{
                  width: '136px',
                  padding: '6px',
                  boxSizing: 'border-box',
                }}
              >
                <Box
                  bold
                  textAlign="center"
                  fontSize="0.85em"
                  style={{ marginBottom: '4px' }}
                >
                  {sphere.name}
                </Box>
                <Box
                  onClick={() => {
                    if (isSelected) {
                      if (assignedPath) {
                        act('clear_personal_instrument', {
                          sphere: sphere.key,
                        });
                      }
                      setSelectedSphere(null);
                    } else {
                      setSelectedSphere(sphere.key);
                    }
                  }}
                  style={{
                    cursor: 'pointer',
                    border: isDiscarded
                      ? DISCARDED_OUTLINE
                      : isSelected
                        ? '1px solid white'
                        : '1px solid rgba(255,255,255,0.1)',
                    boxShadow: isDiscarded ? DISCARDED_GLOW : undefined,
                    borderRadius: '2px',
                    width: '120px',
                    height: '120px',
                    margin: '0 auto',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxSizing: 'border-box',
                    background: isSelected
                      ? 'rgba(255,255,255,0.08)'
                      : 'rgba(0,0,0,0.2)',
                  }}
                >
                  {assignedInfo ? (
                    <Tooltip content={assignedInfo.name}>
                      <InstrumentIcon info={assignedInfo} size="96px" />
                    </Tooltip>
                  ) : (
                    <Box color="label" textAlign="center">
                      None
                    </Box>
                  )}
                </Box>
                {assignedPath && (
                  <Box textAlign="center" style={{ marginTop: '4px' }}>
                    <Button.Checkbox
                      checked={isDiscarded}
                      color="transparent"
                      onClick={() => {
                        act('toggle_discard_instrument', {
                          instrument: assignedPath,
                        });
                      }}
                      tooltip="Discard instrument"
                    >
                      Discard
                    </Button.Checkbox>
                  </Box>
                )}
              </Box>
            );
          })}
        </Box>
      </Stack.Item>

      <Stack.Item>
        <Divider />
      </Stack.Item>

      {/* Instruments */}
      <Stack.Item grow overflowY="auto">
        <Box
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            justifyContent: 'center',
            padding: '8px',
          }}
        >
          {instrumentEntries.map(([path, info]) => {
            const inParadigm = !paradigm || (info.paradigms & paradigm) !== 0;
            const isAssignedToSelected = selectedSphere
              ? sphere_slots[selectedSphere] === path
              : false;
            const isDiscarded = discarded.has(path);
            const canSocket = !!selectedSphere && inParadigm;
            return (
              <Box
                key={path}
                style={{
                  width: '112px',
                  padding: '6px',
                  boxSizing: 'border-box',
                }}
              >
                <Box
                  onClick={() => {
                    if (canSocket) {
                      act('set_personal_instrument', {
                        sphere: selectedSphere,
                        instrument: path,
                      });
                    }
                  }}
                  style={{
                    cursor: canSocket ? 'pointer' : 'not-allowed',
                    border: isDiscarded
                      ? DISCARDED_OUTLINE
                      : isAssignedToSelected
                        ? '1px solid white'
                        : '1px solid rgba(255,255,255,0.1)',
                    boxShadow: isDiscarded ? DISCARDED_GLOW : undefined,
                    borderRadius: '2px',
                    width: '100px',
                    height: '100px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '4px',
                    boxSizing: 'border-box',
                    overflow: 'hidden',
                    background: isAssignedToSelected
                      ? 'rgba(255,255,255,0.08)'
                      : 'rgba(0,0,0,0.2)',
                    opacity: !inParadigm ? 0.35 : 1,
                  }}
                >
                  <InstrumentIcon info={info} dimmed={!inParadigm} size="56px" />
                  {!inParadigm ? (
                    <Tooltip content={`${info.name}`}>
                      <Box
                        bold
                        textAlign="center"
                        fontSize="0.7em"
                        style={{ marginTop: '2px' }}
                      >
                        {info.name}
                      </Box>
                    </Tooltip>
                  ) : info.desc ? (
                    <Tooltip content={info.desc}>
                      <Box
                        bold
                        textAlign="center"
                        fontSize="0.7em"
                        style={{ marginTop: '2px' }}
                      >
                        {info.name}
                      </Box>
                    </Tooltip>
                  ) : (
                    <Box
                      bold
                      textAlign="center"
                      fontSize="0.7em"
                      style={{ marginTop: '2px' }}
                    >
                      {info.name}
                    </Box>
                  )}
                  {/*DO NOT DELETE - <Stack.Item>
                      <Button
                        icon={isDiscarded ? 'rotate-left' : 'trash'}
                        color={isDiscarded ? 'good' : 'bad'}
                        disabled={!inParadigm}
                        tooltip={
                          isDiscarded
                            ? 'Restore instrument'
                            : 'Discard instrument'
                        }
                        onClick={(e) => {
                          e.stopPropagation();
                          act('toggle_discard_instrument', { instrument: path });
                        }}
                      />
                    </Stack.Item>*/}
                </Box>
              </Box>
            );
          })}
        </Box>
      </Stack.Item>
    </Stack>
  );
}
