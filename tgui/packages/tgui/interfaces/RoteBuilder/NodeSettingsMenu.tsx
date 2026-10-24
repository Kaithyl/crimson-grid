import { useState } from 'react';

import { Box, Button, Dropdown, Input, Modal, NumberInput, Section, Stack } from 'tgui-core/components';

import type { EffectData, NodeUserData } from './types';

type Props = {
  effect: EffectData;
  data: NodeUserData;
  onSave: (data: NodeUserData) => void;
  onClose: () => void;
};

const sphereOptionText = (option: Record<string, number>): string =>
  Object.entries(option)
    .map(([sphere, level]) => `${sphere} ${level}`)
    .join(', ');

export const NodeSettingsMenu = (props: Props) => {
  const { effect, data, onSave, onClose } = props;

  const [label, setLabel] = useState(data.label ?? '');
  const [successPercentage, setSuccessPercentage] = useState(data.success_percentage ?? 0);
  const [minSuccess, setMinSuccess] = useState(data.min_success ?? 0);
  const [maxSuccess, setMaxSuccess] = useState(data.max_success ?? 0);
  const [sphereIndex, setSphereIndex] = useState(data.sphere_index ?? 0);

  const sphereOptions = (effect.spheres ?? []).map(sphereOptionText);
  const canChooseSphere = sphereOptions.length > 1;

  const handleSave = () => {
    onSave({
      label,
      success_percentage: successPercentage,
      min_success: minSuccess,
      max_success: maxSuccess,
      sphere_index: sphereIndex,
    });
  };

  return (
    <Modal>
      <Section
        title="Settings"
        buttons={
          <Button color="red" icon="window-close" onClick={onClose}>
            Cancel
          </Button>
        }
      >
        <Stack vertical>
          <Stack.Item>
            <Box color="label" mb={1}>
              Label
            </Box>
            <Input
              fluid
              placeholder={effect.name}
              value={label}
              onChange={setLabel}
            />
          </Stack.Item>

          {sphereOptions.length > 0 && (
            <Stack.Item>
              <Box color="label" mb={1}>
                Sphere Configuration
              </Box>
              {canChooseSphere ? (
                <Dropdown
                  fluid
                  options={sphereOptions}
                  selected={sphereOptions[sphereIndex] ?? sphereOptions[0]}
                  onSelected={(value) => {
                    const index = sphereOptions.indexOf(String(value));
                    setSphereIndex(index >= 0 ? index : 0);
                  }}
                />
              ) : (
                <Box color="label">{sphereOptions[0]}</Box>
              )}
            </Stack.Item>
          )}

          {!!effect.can_add_success && (
            <>
              <Stack.Item>
                <Box color="label" mb={1}>
                  Success Percentage (%)
                </Box>
                <NumberInput
                  value={successPercentage}
                  minValue={0}
                  maxValue={100}
                  step={1}
                  onChange={setSuccessPercentage}
                />
              </Stack.Item>

              <Stack.Item>
                <Box color="label" mb={1}>
                  Min Success
                </Box>
                <NumberInput
                  value={minSuccess}
                  minValue={0}
                  step={1}
                  onChange={setMinSuccess}
                />
              </Stack.Item>

              <Stack.Item>
                <Box color="label" mb={1}>
                  Max Success
                </Box>
                <NumberInput
                  value={maxSuccess}
                  minValue={0}
                  step={1}
                  onChange={setMaxSuccess}
                />
              </Stack.Item>
            </>
          )}

          <Stack.Item textAlign="right">
            <Button onClick={onClose}>Cancel</Button>
            <Button onClick={handleSave} color="good">
              Save
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </Modal>
  );
};
