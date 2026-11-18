// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Adapted from IntegratedCircuit/CircuitInfo.jsx
import { Box, Button, Stack } from 'tgui-core/components';

export type NodeInfoNotice = {
  content: string;
  color?: string;
  icon?: string;
};

type Props = {
  name?: string;
  complexity?: string;
  desc?: string;
  notices: NodeInfoNotice[];
  [key: string]: unknown;
};

export const NodeInfo = (props: Props) => {
  const { name, complexity, desc, notices, ...rest } = props;
  return (
    <Box {...rest}>
      <Stack fill vertical justify="space-around">
        {!!complexity && (
          <Stack.Item maxWidth="200px" style={{ color: '#ffb84d', fontWeight: 'bold' }}>
            {complexity}
          </Stack.Item>
        )}
        {!!desc && (
          <Stack.Item maxWidth="200px" style={{ whiteSpace: 'pre-line' }}>
            {desc}
          </Stack.Item>
        )}
        <Stack.Item>
          <Stack vertical>
            {notices.map((val, index) => (
              <Stack.Item key={index}>
                <Button
                  content={val.content}
                  color={val.color}
                  icon={val.icon}
                  fluid
                />
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
