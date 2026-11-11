// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { useState } from 'react';
import { Box, Button, Dropdown, Input, Modal, NumberInput, Section, Stack } from 'tgui-core/components';

import { sphereOptions as getSphereOptions } from '../serializer';
import type { NodeData, NodeSettings } from '../types';

type Props = {
  node: NodeData;
  settings: NodeSettings;
  readOnly?: boolean;
  onSave: (settings: NodeSettings) => void;
  onClose: () => void;
};

const sphereOptionText = (option: Record<string, number>) =>
  Object.entries(option)
    .map(([sphere, level]) => `${sphere} ${level}`)
    .join(', ');

export const NodeSettingsMenu = ({ node, settings, readOnly, onSave, onClose }: Props) => {
  const [label, setLabel] = useState(settings.label);
  const [successPercentage, setSuccessPercentage] = useState(settings.success_percentage);
  const [minSuccess, setMinSuccess] = useState(settings.min_success);
  const [maxSuccess, setMaxSuccess] = useState(settings.max_success);
  const [sphereIndex, setSphereIndex] = useState(settings.sphere_index);

  const sphereOptions = getSphereOptions(node).map(sphereOptionText);

  const save = () =>
    onSave({
      label,
      success_percentage: successPercentage,
      min_success: minSuccess,
      max_success: maxSuccess,
      sphere_index: sphereIndex,
      port_counts: settings.port_counts,
    });

  return (
    <Modal>
      <Section
        title={readOnly ? 'Settings (view only)' : 'Settings'}
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
            <Input fluid placeholder={node.name} value={label} onChange={setLabel} />
          </Stack.Item>

          {sphereOptions.length > 0 && (
            <Stack.Item>
              <Box color="label" mb={1}>
                Sphere Configuration
              </Box>
              {sphereOptions.length > 1 ? (
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

          {!!node.can_add_success && (
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
                <NumberInput value={minSuccess} minValue={0} step={1} onChange={setMinSuccess} />
              </Stack.Item>
              <Stack.Item>
                <Box color="label" mb={1}>
                  Max Success
                </Box>
                <NumberInput value={maxSuccess} minValue={0} step={1} onChange={setMaxSuccess} />
              </Stack.Item>
            </>
          )}

          <Stack.Item textAlign="right">
            <Button onClick={onClose}>Cancel</Button>
            {!readOnly && (
              <Button onClick={save} color="good">
                Save
              </Button>
            )}
          </Stack.Item>
        </Stack>
      </Section>
    </Modal>
  );
};
