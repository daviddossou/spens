import { Application } from "@hotwired/stimulus"

const applications = []
const errors = []

export async function startStimulus(identifier, controller, html) {
  document.body.innerHTML = html

  const application = Application.start()
  application.handleError = error => errors.push(error)
  application.register(identifier, controller)
  applications.push(application)

  await flushStimulus()
  await flushStimulus()
  throwStimulusErrors()

  return application
}

export function flushStimulus() {
  return new Promise(resolve => setTimeout(resolve, 0))
}

export function stopStimulusApplications() {
  applications.splice(0).forEach(application => application.stop())
  throwStimulusErrors()
}

function throwStimulusErrors() {
  const error = errors.shift()
  errors.length = 0

  if (error) throw error
}
